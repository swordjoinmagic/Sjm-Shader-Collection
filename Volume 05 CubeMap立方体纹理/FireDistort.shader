// 利用GrabPass实现火焰的热浪扭曲屏幕的效果
Shader "Volume 05/GrabPass/Fire Distrotion" {
    Properties {
        // 扭曲采样方向的噪声图
        _NoiseTex("Noise Texture",2D) = "white" {}
    }
    SubShader {
        // GrabPass谨记要放到所有不透明物体之后渲染
        Tags {"Queue"="Transparent" "RenderType"="Opaque"}

        // 把屏幕图像扔到_ScreenTex里去
        GrabPass{ "_ScreenTex" }

        Pass {

            CGPROGRAM
            #include "UnityCG.cginc"

            #pragma vertex vert
            #pragma fragment frag

            sampler2D _NoiseTex;
            sampler2D _ScreenTex;

            struct a2v{
                float4 vertex : POSITION;
                float2 texcoord : TEXCOORD0;                
            };

            struct v2f{
                float4 pos : SV_POSITION;
                float2 uv : TEXCOORD0;
                float4 screenPos : TEXCOORD1;
            };

            v2f vert(a2v v){
                v2f o;

                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv = v.texcoord;
                o.screenPos = ComputeGrabScreenPos(o.pos);

                return o;
            }

            fixed4 frag(v2f i) : SV_TARGET{
                // 向噪声图采样
                fixed3 noise = tex2D(_NoiseTex,i.uv + _Time.xy);

                float2 scrPos = i.screenPos.xy/i.screenPos.w;

                // 根据噪声对uv进行偏移，并对屏幕坐标进行采样
                fixed3 color = tex2D(_ScreenTex,scrPos-noise*0.02);

                return fixed4(color,1.0);
            }

            ENDCG
        }
    }
    FallBack "Diffuse"
    
}