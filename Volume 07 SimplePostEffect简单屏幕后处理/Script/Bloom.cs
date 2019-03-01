using UnityEngine;

/// <summary>
/// 屏幕后处理特效之——Bloom，
/// 原理：
///     1. 用一个亮度阈值LuminanceThreshold来提取图像中较亮的部分，
///     2. 使用高斯模糊对Bloom图进行模糊
///     3. 将Bloom图和原图混合
/// </summary>
public class Bloom : PostEffectBase{

    // 用于Bloom的shader
    public Shader bloomShader;
    private Material bloomMaterial;

    public Material BloomMaterial {
        get {
            if (bloomMaterial == null) bloomMaterial = CheckShaderAndCreateMaterial(bloomShader);
            return bloomMaterial;
        }
    }

    // 用于高斯模糊的Shader
    public Shader gaussianBlurShader;
    private Material gaussianBlurMaterial;

    public Material GaussianBlurMaterial {
        get {
            if (gaussianBlurMaterial == null) gaussianBlurMaterial = CheckShaderAndCreateMaterial(gaussianBlurShader);
            return gaussianBlurMaterial;
        }
    }

    // 模糊迭代次数
    [Range(0,5)]
    public int iteration = 1;

    // 模糊半径
    [Range(1,10)]
    public float blurSize = 1;

    // RT的降分辨率比例
    [Range(0,5)]
    public int downSample = 1;

    // Bloom亮度阈值
    [Range(0f,4)]
    public float luminanceThroshle = 0.5f;

    private void OnRenderImage(RenderTexture source, RenderTexture destination) {
        if (GaussianBlurMaterial != null && BloomMaterial != null) {

            gaussianBlurMaterial.SetFloat("_BlurSize",blurSize);
            bloomMaterial.SetFloat("_LuminanceThreshold", luminanceThroshle);

            // 申请两张RT用于模糊迭代
            RenderTexture rt1 = RenderTexture.GetTemporary(source.width>>downSample,source.height>>downSample,0,source.format);
            RenderTexture rt2 = RenderTexture.GetTemporary(source.width >> downSample, source.height >> downSample, 0, source.format);

            // 将Bloom图扔到rt1
            Graphics.Blit(source,rt1,bloomMaterial,0);

            for (int i = 0; i < iteration; i++) {
                // 模糊Bloom图
                Graphics.Blit(rt1, rt2, gaussianBlurMaterial, 0);  // 竖
                Graphics.Blit(rt2, rt1, gaussianBlurMaterial, 1);  // 横
            }

            bloomMaterial.SetTexture("_Bloom",rt1);
            // 把经过模糊的Bloom图和原图进行混合
            Graphics.Blit(source,destination,BloomMaterial,1);

            // 释放内存
            RenderTexture.ReleaseTemporary(rt1);
            RenderTexture.ReleaseTemporary(rt2);
        } else {
            Graphics.Blit(source,destination);
        }
    }
}

