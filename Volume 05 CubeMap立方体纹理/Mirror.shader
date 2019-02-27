// 用RT模拟镜面特效
Shader "Volume 05/Render Texture/Mirror" {
    Properties {
        // RT图
        _MainTex("Main Texture",2D) = "white" {}
    }
    SubShader {
        Pass {
            CGPROGRAM
            
            #include "UnityCG.cginc"

            #pragma vertex vert
            #pragma fragment frag

            sampler2D _MainTex;

            struct v2f{
                float4 pos : SV_POSITION;
                fixed2 uv : TEXCOORD0;
            };

            v2f vert(appdata_img v){
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv = v.texcoord;
                return o;
            }

            fixed4 frag(v2f i) : SV_TARGET{
                // 镜面对称
                fixed2 uv = fixed2(1-i.uv.x,i.uv.y);
                return tex2D(_MainTex,uv);
            }

            ENDCG
        }
    }
    FallBack "Diffuse"
    
}