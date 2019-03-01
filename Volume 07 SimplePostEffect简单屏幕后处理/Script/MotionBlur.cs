using UnityEngine;

public class MotionBlur : PostEffectBase {
    public Shader motionBlurShader;
    private Material motionBlurMaterial = null;

    public Material Material {
        get {
            if(motionBlurMaterial==null)
                motionBlurMaterial = CheckShaderAndCreateMaterial(motionBlurShader);
            return motionBlurMaterial;
        }
    }

    [Range(0.0f, 0.9f)]
    public float blurAmount = 0.5f;

    private RenderTexture accumulationTexture;

    void OnDisable() {
        DestroyImmediate(accumulationTexture);
    }

    void OnRenderImage(RenderTexture src, RenderTexture dest) {
        if (Material != null) {
            // Create the accumulation texture
            if (accumulationTexture == null ||
                accumulationTexture.width != src.width ||
                accumulationTexture.height != src.height) {

                DestroyImmediate(accumulationTexture);
                accumulationTexture = new RenderTexture(src.width, src.height, 0);
                accumulationTexture.hideFlags = HideFlags.HideAndDontSave;
                Graphics.Blit(src, accumulationTexture);

            }

            // We are accumulating motion over frames without clear/discard
            // by design, so silence any performance warnings from Unity
            accumulationTexture.MarkRestoreExpected();

            Material.SetFloat("_BlurAmount", 1.0f - blurAmount);

            Graphics.Blit(src, accumulationTexture, Material);
            Graphics.Blit(accumulationTexture, dest);
        } else {
            Graphics.Blit(src, dest);
        }
    }
}

