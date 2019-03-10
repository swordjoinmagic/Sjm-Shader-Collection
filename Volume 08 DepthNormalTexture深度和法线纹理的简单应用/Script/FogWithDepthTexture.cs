using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class FogWithDepthTexture : PostEffectBase {
    public Shader fogShader;
    private Material material;

    public Material Material {
        get {
            if (material == null)
                material = CheckShaderAndCreateMaterial(fogShader);
            return material;
        }
    }

    public Transform CameraTransform {
        get {
            return Camera.main.transform;
        }
    }

    // 雾的强度
    [Range(0.0f,3.0f)]
    public float fogDensity = 1.0f;

    public Color fogColor = Color.white;

    public float fogStart = 0f;
    public float fogEnd = 2.0f;

    private void OnEnable() {
        // 设置当前摄像机可以获取深度图
        Camera.main.depthTextureMode |= DepthTextureMode.Depth;
    }

    private void OnRenderImage(RenderTexture source, RenderTexture destination) {
        if (Material != null) {

            Matrix4x4 frustumConrners = Matrix4x4.identity;

            float fov = Camera.main.fieldOfView;
            float near = Camera.main.nearClipPlane;
            float far = Camera.main.farClipPlane;
            float aspect = Camera.main.aspect;

            float halfHeight = near * Mathf.Tan(fov*0.5f*Mathf.Deg2Rad);
            Vector3 toRight = CameraTransform.right * halfHeight * aspect;
            Vector3 toTop = CameraTransform.up * halfHeight;

            Vector3 topLeft = CameraTransform.forward * near + toTop - toRight;
            float scale = topLeft.magnitude / near;

            topLeft.Normalize();
            topLeft *= scale;

            Vector3 topRight = CameraTransform.forward * near + toRight + toTop;
            topRight.Normalize();
            topRight *= scale;

            Vector3 buttomLeft = CameraTransform.forward * near - toTop - toRight;
            buttomLeft.Normalize();
            buttomLeft *= scale;

            Vector3 buttomRight = CameraTransform.forward * near + toRight - toTop;
            buttomRight.Normalize();
            buttomRight *= scale;

            frustumConrners.SetRow(0,buttomLeft);
            frustumConrners.SetRow(1,buttomRight);
            frustumConrners.SetRow(2,topRight);
            frustumConrners.SetRow(3,topLeft);

            material.SetMatrix("_FrustumCornersRay",frustumConrners);

            material.SetFloat("_FogDensity",fogDensity);
            material.SetColor("_FogColor",fogColor);
            material.SetFloat("_FogStart",fogStart);
            material.SetFloat("_FogEnd",fogEnd);

            Graphics.Blit(source,destination,material);
        } else {
            Graphics.Blit(source,destination);
        }
    }
}
