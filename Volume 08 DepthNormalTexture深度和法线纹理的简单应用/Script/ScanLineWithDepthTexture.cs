using UnityEngine;

public class ScanLineWithDepthTexture : PostEffectBase{
    public Shader scanLineShader;
    private Material material;

    // 扫描线阈值
    [Range(0.0f, 1.0f)]
    public float scanLineThrosle = 0;

    // 扫描线宽度
    [Range(0.0f, 1.0f)]
    public float scanLineWidth = 0.05f;

    // 扫描线强度
    [Range(0,10)]
    public float scanLineStrength = 1;

    // 扫描线颜色
    public Color scanLineColor = Color.white;

    public Material Material {
        get {
            if (material == null) material = CheckShaderAndCreateMaterial(scanLineShader);
            return material;
        }
    }

    private void OnRenderImage(RenderTexture source, RenderTexture destination) {
        if (Material != null) {

            material.SetFloat("_Width",scanLineWidth);
            material.SetFloat("_Throsle",scanLineThrosle);
            material.SetFloat("_ScanLineStrength",scanLineStrength);
            material.SetColor("_Color",scanLineColor);

            Graphics.Blit(source,destination,material);

        } else {
            Graphics.Blit(source,destination);
        }
    }
}
