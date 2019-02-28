using UnityEngine;

public class EdgeDetection : PostEffectBase{
    public Shader edgeDetectionShader;
    private Material material;
    
    [Range(0,1)]
    public float edgeOnly; 

    public Color edgeColor;

    public Color backgroundColor;

    public Material Material {
        get {
            if (material == null)
                material = CheckShaderAndCreateMaterial(edgeDetectionShader);
            return material;
        }
    }

    private void OnRenderImage(RenderTexture source, RenderTexture destination) {
        if (Material != null) {

            material.SetFloat("_EdgeOnly",edgeOnly);
            material.SetColor("_EdgeColor",edgeColor);
            material.SetColor("_BackgroundColor",backgroundColor);

            Graphics.Blit(source,destination,material);

        } else {
            Graphics.Blit(source,destination);
        }
    }
}

