// Bloom后处理特效
Shader "Volume 07/SimplePostEffect/Bloom" {
    Properties {
        _MainTex("Main Texture",2D) = "white" {}
        // 亮度阈值,Bloom特效根据亮度阈值提取图像中较亮区域作为Bloom图与原图混合
        _LuminanceThreshold("Luminance Threshold",Float) = 0.5
    }
    SubShader {

        // 用于提取图中较亮区域的Pass
        Pass {
        
            CGPROGRAM
            
            #include "UnityCG.cginc"

            #pragma vertex vertGetBloom
            #pragma fragment fragGetBloom

            sampler2D _MainTex;
            float _LuminanceThreshold;

            struct v2f{
                float4 pos : SV_POSITION;
                float2 uv : TEXCOORD0;
            };

            v2f vertGetBloom(appdata_img v){
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv = v.texcoord;
                return o;
            }

            fixed4 fragGetBloom(v2f i) : SV_TARGET{
                fixed3 color = tex2D(_MainTex,i.uv);

                // 计算该点的亮度值
                fixed luminance = Luminance(color);

                // 提取亮度大于阈值的部分 
                fixed val = clamp(luminance-_LuminanceThreshold,0,1.0);

                return fixed4(color*val,1.0); 
            }

            ENDCG

        }

        // 用于混合Bloom图和原图的Pass
        Pass{
            CGPROGRAM

            #include "UnityCG.cginc"
            
            #pragma vertex vertMixture
            #pragma fragment fragMixture

            sampler2D _MainTex;
            float _LuminanceThreshold;

            // 经过模糊后的Bloom图
            sampler2D _Bloom;

            struct v2f{
                float4 pos : SV_POSITION;
                float2 uv : TEXCOORD0;
            };

            v2f vertMixture(appdata_img v){
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv = v.texcoord;
                return o;
            }

            fixed4 fragMixture(v2f i) : SV_TARGET{
                // 混合原图和Bloom图
                return tex2D(_MainTex,i.uv) + tex2D(_Bloom,i.uv);
            }

            ENDCG
        }
    }
    FallBack "Diffuse"
    
}