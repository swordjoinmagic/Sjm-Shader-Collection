using UnityEngine;

public class ShowDepth : PostEffectBase{
    private void OnEnable() {
        // 设置摄像机可以获得深度图
        Camera.main.depthTextureMode |= DepthTextureMode.Depth;
    }

    public Shader showDepthShader;
    private Material material;

    public Material Material {
        get {
            if (material == null) material = CheckShaderAndCreateMaterial(showDepthShader);
            return material;
        }
    }

    private void OnRenderImage(RenderTexture source, RenderTexture destination) {
        if (Material == null) {
            Graphics.Blit(source, destination);
        } else {
            Graphics.Blit(source,destination,material);
        }
    }
}