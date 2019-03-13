using UnityEngine;
using UnityEngine.Rendering;

/// <summary>
/// 用于子弹时间【1】的屏幕后处理脚本
/// 
/// 基于世界坐标上某一点，从该点开始，
/// 将距离该点由近到远的物体全部刷上边缘检测（或者从黑白的边缘线中着色），
/// 同时，支持在全黑白的边缘检测图像中，由一个Mask图，将某个特定单位上色
/// </summary>
public class BulletTimeStartWithEdgeDetection : PostEffectBase{
    public Shader shader;
    private Material material;
    public Material Material {
        get {
            if (material == null)
                material = CheckShaderAndCreateMaterial(shader);
            return material;
        }
    }

    public Material OutlineSoliderMaterial {
        get {
            if (outlineSoliderMaterial == null) outlineSoliderMaterial = CheckShaderAndCreateMaterial(outlineSoliderColorShader);
            return outlineSoliderMaterial;
        }
    }

    // 用于渲染描边人物的纯色Shader
    public Shader outlineSoliderColorShader;
    private Material outlineSoliderMaterial;

    // 要进行描边的目标对象
    public GameObject targetObject;

    // CommandBuffer的渲染目标
    private RenderTexture maskTexture;
    private CommandBuffer commandBuffer;


    // 是否只显示边缘色
    [Range(0, 1f)]
    public float edgesOnly = 0.0f;
    // 边缘颜色
    public Color edgeColor = Color.black;
    // 背景色
    public Color backgroundColor = Color.white;
    // 描边的宽度
    public float sampleDistance = 1.0f;

    // 深度及法线灵敏度,将会影响当邻域的深度值或法线值相差多少时,会被认为存在一条边界
    public float sensitivityDepth = 1.0f;
    public float sensitivityNormals = 1.0f;

    // Mask图,用于取消某些单位的描边
    private Texture maskTex;

    // 噪声图,用于将扩散的扫描边扩散方式变得随机
    public Texture noiseTex;

    // 扫描线阈值
    public float scanLineThrosle = 0;

    // 扫描线中心点
    public Vector3 centerPos = Vector3.zero;

    private void OnEnable() {
        GetComponent<Camera>().depthTextureMode |= DepthTextureMode.DepthNormals;

        // 用于存放纯色Mask图
        maskTexture = RenderTexture.GetTemporary(Screen.width, Screen.height, 0);

        // 创建用于渲染纯色目标RT的CommandBuffer
        commandBuffer = new CommandBuffer();
        commandBuffer.SetRenderTarget(maskTexture);
        commandBuffer.ClearRenderTarget(true, true, Color.black);
        // 将目标物体的所有render都扔到CommandBuffer里面去
        Renderer[] renderers = targetObject.GetComponentsInChildren<Renderer>();
        foreach (Renderer r in renderers) {
            commandBuffer.DrawRenderer(r, OutlineSoliderMaterial);
        }
    }

    private void OnDisable() {
        if (maskTexture != null) {
            RenderTexture.ReleaseTemporary(maskTexture);
            maskTexture = null;
        }
        if (commandBuffer != null) {
            commandBuffer.Release();
            commandBuffer = null;
        }
    }

    // 在所有不透明物体渲染之后调用
    [ImageEffectOpaque]
    private void OnRenderImage(RenderTexture source, RenderTexture destination) {
        if (Material != null) {
            // 通过Graphic执行Command Buffer
            Graphics.ExecuteCommandBuffer(commandBuffer);

            material.SetFloat("_EdgeOnly", edgesOnly);
            material.SetColor("_EdgeColor", edgeColor);
            material.SetColor("_BackgroundColor", backgroundColor);
            material.SetFloat("_SampleDistance", sampleDistance);
            material.SetVector("_Sensitivity", new Vector4(sensitivityNormals, sensitivityDepth, 0, 0));
            material.SetTexture("_MaskTex", maskTex);
            material.SetFloat("_Throsle", scanLineThrosle);
            material.SetTexture("_NoiseTex",noiseTex);
            material.SetVector("_CenterPos", centerPos);

            // 得到当前摄像机的fov角度,
            // 近裁剪平面距离,远裁剪平面距离,
            // 以及用于获取近裁剪平面和远裁剪平面的aspect比值
            float fov = Camera.main.fieldOfView;
            float near = Camera.main.nearClipPlane;
            float far = Camera.main.farClipPlane;
            float aspect = Camera.main.aspect;

            float halfHeight = near * Mathf.Tan(fov * 0.5f * Mathf.Deg2Rad);
            Vector3 toRight = Camera.main.transform.right * halfHeight * aspect;
            Vector3 toTop = Camera.main.transform.up * halfHeight;

            Vector3 topLeft = Camera.main.transform.forward * near + toTop - toRight;
            float scale = topLeft.magnitude / near;
            topLeft.Normalize();
            topLeft *= scale;


            Vector3 topRight = Camera.main.transform.forward * near + toRight + toTop;
            topRight.Normalize();
            topRight *= scale;


            Vector3 bottomLeft = Camera.main.transform.forward * near - toRight - toTop;
            bottomLeft.Normalize();
            bottomLeft *= scale;


            Vector3 bottomRight = Camera.main.transform.forward * near + toRight - toTop;
            bottomRight.Normalize();
            bottomRight *= scale;

            Matrix4x4 frustumConrners = Matrix4x4.identity;

            frustumConrners.SetRow(0, bottomLeft);
            frustumConrners.SetRow(1, bottomRight);
            frustumConrners.SetRow(2, topRight);
            frustumConrners.SetRow(3, topLeft);


            // 设置Mask图
            material.SetTexture("_MaskTex",maskTexture);
            material.SetMatrix("_FrustumCornersRay", frustumConrners);
            material.SetFloat("_Far",far);

            Graphics.Blit(source, destination, material);
        } else {
            Graphics.Blit(source, destination);
        }
    }
}

