/*
    材质捕获
*/
Shader "Volume 02/Texture/Material Capture" {
    Properties {
        // 材质捕获贴图
        _MatCapTex("MatCap Texture",2D) = "white" {}
        // 材质贴图
        _MainTex("Main Texture",2D) = "white" {}
        
    }
    SubShader {
        Tags { "RenderType"="Opaque"  "Queue"="Geometry" }
        Pass {
            CGPROGRAM
            
            sampler2D _MatCapTex;

            #pragma vertex vert
            #pragma fragment frag

            struct a2v{
                float4 vertex : POSITION;
                float3 normal : NORMAL;                
            };

            struct v2f{
                float4 pos : SV_POSITION;
                float2 matcapUv : TEXCOORD0;                
            };

            v2f vert(a2v v){
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);

                // 将法线变换到观察空间
                float3 viewNormal = mul(UNITY_MATRIX_IT_MV,v.normal);
                viewNormal = normalize(viewNormal);
                o.matcapUv = viewNormal.xy * 0.5 + 0.5;
                return o;
            }

            fixed4 frag(v2f i) : SV_TARGET{
                fixed4 color = tex2D(_MatCapTex,i.matcapUv);
                return color;
            }

            ENDCG
        }
    }
    FallBack "Diffuse"
    
}