using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class RadialBlurEffect : PostEffectBase {

    public Shader shader;
    private Material material;

    public Material Material {
        get {
            if (material == null) material = CheckShaderAndCreateMaterial(shader);
            return material;
        }
    }

    [Range(0f,1f)]
    public float centerPosX;
    [Range(0f,1f)]
    public float centerPosY;

    private void OnRenderImage(RenderTexture source, RenderTexture destination) {
        if (Material != null) {

            Vector4 vector4 = new Vector4(centerPosX,centerPosY);
            material.SetVector("_CenterPoint",vector4);

            Graphics.Blit(source,destination,material);

        } else {
            Graphics.Blit(source,destination);
        }
    }
}
