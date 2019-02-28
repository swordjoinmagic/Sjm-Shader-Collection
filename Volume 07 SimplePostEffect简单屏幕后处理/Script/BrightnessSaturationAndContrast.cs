using UnityEngine;

public class BrightnessSaturationAndContrast : PostEffectBase{

    // 亮度
    [Range(1,2)]
    public float Brightness;

    // 对比度
    [Range(0,1)]
    public float Contrast;

    // 饱和度
    [Range(0, 1)]
    public float Saturation;

    // 用于调整亮度、饱和度、对比度的Shader
    public Shader BrightnessSaturationAndContrastShader;
    private Material material;

    public Material Material {
        get {
            if (material == null)
                material = CheckShaderAndCreateMaterial(BrightnessSaturationAndContrastShader);
            return material;
        }
    }

    private void OnRenderImage(RenderTexture source, RenderTexture destination) {
        if (Material != null) {

            material.SetFloat("_Brightness", Brightness);
            material.SetFloat("_Contrast", Contrast);
            material.SetFloat("_Saturation", Saturation);

            Graphics.Blit(source,destination,material);

        } else {
            Graphics.Blit(source,destination);
        }
    }
}

