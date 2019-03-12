using UnityEngine;

public class ScanLineWithRebuildWorldPos : PostEffectBase{

    public Shader scanLineShader;
    private Material material;

    public Material Material {
        get {
            if (material == null) material = CheckShaderAndCreateMaterial(scanLineShader);
            return material;
        }
    }

    // 扫描线阈值
    [Range(0.0f, 10.0f)]
    public float scanLineThrosle = 0;

    // 扫描线宽度
    [Range(0.0f, 10.0f)]
    public float scanLineWidth = 0.05f;

    // 扫描线强度
    [Range(0, 10)]
    public float scanLineStrength = 1;

    // 扫描线颜色
    public Color scanLineColor = Color.white;

    // 扫描线中心点
    public Vector3 centerPos = Vector3.zero;

    private void OnEnable() {
        Camera.main.depthTextureMode |= DepthTextureMode.Depth;
    }

    private void OnRenderImage(RenderTexture source, RenderTexture destination) {
        if (Material == null) {
            Graphics.Blit(source, destination);
        } else {

            // 得到当前摄像机的fov角度,
            // 近裁剪平面距离,远裁剪平面距离,
            // 以及用于获取近裁剪平面和远裁剪平面的aspect比值
            float fov = Camera.main.fieldOfView;
            float near = Camera.main.nearClipPlane;
            float far = Camera.main.farClipPlane;
            float aspect = Camera.main.aspect;

            float halfHeight = near * Mathf.Tan(fov*0.5f*Mathf.Deg2Rad);
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

            frustumConrners.SetRow(0,bottomLeft);
            frustumConrners.SetRow(1,bottomRight);
            frustumConrners.SetRow(2,topRight);
            frustumConrners.SetRow(3,topLeft);

            material.SetMatrix("_FrustumCornersRay",frustumConrners);
            material.SetFloat("_Width",scanLineWidth);
            material.SetFloat("_Throsle",scanLineThrosle);
            material.SetFloat("_Strength",scanLineStrength);
            material.SetColor("_Color",scanLineColor);
            material.SetVector("_CenterPos",centerPos);

            Graphics.Blit(source,destination,material); 
        }
    }
}

