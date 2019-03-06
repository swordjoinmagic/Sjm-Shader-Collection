using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class MotionBlurWithDepthTexture : PostEffectBase{
    public Shader motionBlurWithDepthTextureShader;
    private Material material;

    public Material Material {
        get {
            if (material == null)
                material = CheckShaderAndCreateMaterial(motionBlurWithDepthTextureShader);
            return material;
        }
    }

    [Range(0.0f,1.0f)]
    public float blurSize = 0.5f;

    private void OnEnable() {
        Camera.main.depthTextureMode |= DepthTextureMode.Depth;
    }

    // View-Projection变换矩阵
    private Matrix4x4 previousViewProjectionMatrix;

    private void OnRenderImage(RenderTexture source, RenderTexture destination) {
        if (Material != null) {

            material.SetFloat("_BlurSize",blurSize);

            material.SetMatrix("_PreviousViewProjectionMatrix", previousViewProjectionMatrix);
            // 当前帧的View-Projection变换矩阵
            Matrix4x4 currentViewProjectionMatrix = Camera.main.projectionMatrix * Camera.main.worldToCameraMatrix;
            // 当前帧的Projection-View变换矩阵
            Matrix4x4 currentViewProjectionInverseMatrix = currentViewProjectionMatrix.inverse;
            material.SetMatrix("_CurrentViewProjectionInverseMatrix",currentViewProjectionInverseMatrix);
            // 上一帧的View-Projection变换矩阵
            previousViewProjectionMatrix = currentViewProjectionMatrix;

            Graphics.Blit(source,destination,material);

        } else {
            Graphics.Blit(source,destination);
        }
    }
}
