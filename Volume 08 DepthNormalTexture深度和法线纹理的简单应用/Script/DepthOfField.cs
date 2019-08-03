using UnityEngine;

public class DepthOfField : PostEffectBase {
    // 用于高斯模糊的Shader
    public Shader blurShader;
    private Material blurMaterial;
    public Material BlurMaterial {
        get {
            if (blurMaterial == null) blurMaterial = CheckShaderAndCreateMaterial(blurShader);
            return blurMaterial;
        }
    }

    public Material DepthOfFieldMaterial {
        get {
            if (depthOfFieldMaterial == null) depthOfFieldMaterial = CheckShaderAndCreateMaterial(depthOfFieldShader);
            return depthOfFieldMaterial;
        }
    }

    // 用于景深效果的Shader
    public Shader depthOfFieldShader;
    private Material depthOfFieldMaterial;

    // 高斯模糊迭代次数
    [Range(0, 10)]
    public int iterations;

    // 模糊半径
    [Range(0f, 10)]
    public float BlurRadius;

    // 降RT的分辨率
    [Range(0, 5)]
    public int downSample = 2;

    // 焦点的深度值
    [Range(-100,100)]
    public float focusDepth;

    [Range(1,5)]
    public float FarBlurScale;

    [Range(1,5)]
    public float NearBlurScale;

    private void OnEnable() {
        Camera.main.depthTextureMode |= DepthTextureMode.Depth;
    }
    private void OnDisable() {
        Camera.main.depthTextureMode &= ~DepthTextureMode.Depth;
    }

    private void OnRenderImage(RenderTexture source, RenderTexture destination) {
        if (BlurMaterial != null && DepthOfFieldMaterial != null) {

            // 在迭代过程中逐步增加采样半径
            blurMaterial.SetFloat("_BlurSize", BlurRadius);

            // 申请两张RT，用于高斯模糊迭代，右移downSample位表示，原值/2的downSample次方
            RenderTexture rt1 = RenderTexture.GetTemporary(source.width >> downSample, source.height >> downSample, 0, source.format);
            RenderTexture rt2 = RenderTexture.GetTemporary(source.width >> downSample, source.height >> downSample, 0, source.format);

            //=============================================
            // 第一步，先对原图进行一个高斯模糊,并放到RT1中

            // 将原图进行竖直方向卷积，并把模糊过后的图像给rt1
            Graphics.Blit(source, rt2, blurMaterial, 0);
            // 将原图进行水平方向卷积，并把模糊过后的图像给rt2
            Graphics.Blit(rt2, rt1, blurMaterial, 1);

            for (int i = 0; i < iterations; i++) {
                // 在迭代过程中逐步增加采样半径
                blurMaterial.SetFloat("_BlurSize", BlurRadius * i + 1.0f);
                Graphics.Blit(rt1, rt2, blurMaterial, 0);
                Graphics.Blit(rt2, rt1, blurMaterial, 1);
            }

            //===========================================================
            // 第二步，将原图与高斯模糊后的图根据距离焦点的深度值进行混合

            depthOfFieldMaterial.SetTexture("_BlurTex",rt1);
            depthOfFieldMaterial.SetFloat("_FarBlurScale",FarBlurScale);
            depthOfFieldMaterial.SetFloat("_NearBlurScale",NearBlurScale);

            // 被归一化的、观察空间下的深度值
            float depthOfView01 =
                Camera.main.WorldToViewportPoint(
                    (focusDepth - Camera.main.nearClipPlane)
                    * Camera.main.transform.forward +
                    Camera.main.transform.position
                ).z 
                /
                (
                    Camera.main.farClipPlane
                    - Camera.main.nearClipPlane
                );

            // 将焦点的深度值归一化
            depthOfFieldMaterial.SetFloat("_FocusDepth",depthOfView01);

            Graphics.Blit(source,destination,depthOfFieldMaterial);


            // 释放RT申请的内存
            RenderTexture.ReleaseTemporary(rt1);
            RenderTexture.ReleaseTemporary(rt2);
        } else {
            Graphics.Blit(source,destination);
        }
    }
}

