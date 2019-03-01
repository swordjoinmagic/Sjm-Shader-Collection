using UnityEngine;

namespace Assets.Shaders.Volume_07_SimplePostEffect简单屏幕后处理.Script {
    public class GaussianBlur : PostEffectBase{

        // 高斯模糊迭代次数
        [Range(0, 10)]
        public int iterations;

        // 模糊半径
        [Range(0f,10)]
        public float BlurRadius;

        // 降RT的分辨率
        [Range(0,5)]
        public int downSample = 2;

        // 用于高斯模糊的Shader
        public Shader gaussianBlurShader;
        private Material material;
        private Material Material {
            get {
                if (material == null)
                    material = CheckShaderAndCreateMaterial(gaussianBlurShader);
                return material;
            }
        }


        private void OnRenderImage(RenderTexture source, RenderTexture destination) {
            if (Material != null) {

                // 在迭代过程中逐步增加采样半径
                Material.SetFloat("_BlurSize", BlurRadius);

                // 申请两张RT，用于高斯模糊迭代，右移downSample位表示，原值/2的downSample次方
                RenderTexture rt1 = RenderTexture.GetTemporary(source.width>>downSample,source.height>>downSample,0,source.format);
                RenderTexture rt2 = RenderTexture.GetTemporary(source.width>>downSample,source.height>>downSample,0,source.format);

                // 将原图进行竖直方向卷积，并把模糊过后的图像给rt1
                Graphics.Blit(source, rt2, material,0);
                // 将原图进行水平方向卷积，并把模糊过后的图像给rt2
                Graphics.Blit(rt2, rt1, material,1);

                for (int i=0;i<iterations;i++) {

                    // 在迭代过程中逐步增加采样半径
                    Material.SetFloat("_BlurSize", BlurRadius * i + 1.0f);

                    Graphics.Blit(rt1,rt2,material,0);
                    Graphics.Blit(rt2,rt1,material,1);

                }

                Graphics.Blit(rt1,destination);

                // 释放RT申请的内存
                RenderTexture.ReleaseTemporary(rt1);
                RenderTexture.ReleaseTemporary(rt2);

            } else {
                Graphics.Blit(source,destination);
            }
        }
    }
}
