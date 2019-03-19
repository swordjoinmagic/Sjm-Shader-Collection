Shader "Volume 11/Toon/Hatching" {
    Properties {
        _Color("Color",Color) = (1, 1, 1, 1)
        _TileFactor("Tile Factor",Float) = 1
        _OutlineWidth("Outline",Range(0,1)) = 0.1
        _OutlineColor("OutLine Color",Color) = (1, 1, 1, 1)
        _Hatch0("Hatch 0",2D) = "white"{}
        _Hatch1("Hatch 1",2D) = "white" {}    
        _Hatch2("Hatch 2",2D) = "white" {}
        _Hatch3("Hatch 3",2D) = "white" {}
        _Hatch4("Hatch 4",2D) = "white" {}
        _Hatch5("Hatch 5",2D) = "white" {}
    }
    SubShader {
        Tags { "RenderType"="Opaque" "Queue"="Geometry" }

        // 描边Pass
        Pass {
            Tags { "LightMode"="ForwardBase" }

            // 剔除正面
            Cull Front

            CGPROGRAM
            
            #pragma vertex vert
            #pragma fragment frag

            struct a2v{
                float4 vertex : POSITION;
                float3 normal : NORMAL;
            };

            struct v2f{
                float4 pos : SV_POSITION;                
            };

            fixed4 _OutlineColor;
            float _OutlineWidth;

            v2f vert(a2v v){
                v2f o;
                // 将单位的法线和顶点变换到视角空间
                float4 viewPos = mul(UNITY_MATRIX_MV,v.vertex);
                float3 viewNormal = mul((float3x3)UNITY_MATRIX_IT_MV,v.normal);

                viewNormal.z = -0.5;
                viewNormal = normalize(viewNormal);
                viewPos.xyz += viewNormal * _OutlineWidth;

                // 将顶点从观察空间变换到裁剪空间去
                o.pos = mul(UNITY_MATRIX_P,viewPos);
                return o;
            }

            fixed4 frag(v2f i) : SV_TARGET{
                return fixed4(_OutlineColor.rgb,1.0);
            }

            ENDCG
        }

        Pass {
            Tags{ "LightMode"="ForwardBase" }
            CGPROGRAM
            
            #include "UnityCG.cginc"

            #pragma vertex vert
            #pragma fragment frag

            fixed4 _Color;
            float _TileFactor;
            sampler2D _Hatch0;
            sampler2D _Hatch1;
            sampler2D _Hatch2;
            sampler2D _Hatch3;
            sampler2D _Hatch4;
            sampler2D _Hatch5;

            struct v2f{
                float4 pos : SV_POSITION;
                float2 uv : TEXCOORD0;
                fixed3 hatchWeights0 : TEXCOORD1;
                fixed3 hatchWeights1 : TEXCOORD2;            
            };

            struct a2v{
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float2 texcoord : TEXCOORD0;
            };

            v2f vert(a2v v){
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);

                o.uv = v.texcoord.xy * _TileFactor;

                float3 worldPos = mul(unity_ObjectToWorld,v.vertex).xyz;
                fixed3 worldLightDir = normalize(UnityWorldSpaceLightDir(worldPos));
                fixed3 worldNormalDir = normalize(UnityObjectToWorldNormal(v.normal));

                fixed diff = max(0,dot(worldLightDir,worldNormalDir));

                o.hatchWeights0 = fixed3(0,0,0);
                o.hatchWeights1 = fixed3(0,0,0);

                float hatchFactor = diff * 7.0;

                if(hatchFactor>6.0){

                }else if(hatchFactor > 5.0){
                    o.hatchWeights0.x = hatchFactor - 5.0;
                }else if(hatchFactor > 4.0){
                    o.hatchWeights0.x = hatchFactor - 4.0;
                    o.hatchWeights0.y = 1.0 - o.hatchWeights0.x;
                }else if(hatchFactor > 3.0){
                    o.hatchWeights0.y = hatchFactor - 3.0;
                    o.hatchWeights0.z = 1.0 - o.hatchWeights0.y;
                }else if(hatchFactor > 2.0){
                    o.hatchWeights0.z = hatchFactor - 2.0;
                    o.hatchWeights1.x = 1.0 - o.hatchWeights0.z;
                }else if(hatchFactor > 1.0){
                    o.hatchWeights1.x = hatchFactor - 1.0;
                    o.hatchWeights1.y = 1.0 - o.hatchWeights1.x;
                }else{
                    o.hatchWeights1.y = hatchFactor;
                    o.hatchWeights1.z = 1.0 - o.hatchWeights1.y;
                }

                return o;
            }

            fixed4 frag(v2f i) : SV_TARGET{
                fixed4 hatchTex0 = tex2D(_Hatch0,i.uv) * i.hatchWeights0.x;
                fixed4 hatchTex1 = tex2D(_Hatch1,i.uv) * i.hatchWeights0.y;
                fixed4 hatchTex2 = tex2D(_Hatch2,i.uv) * i.hatchWeights0.z;
                fixed4 hatchTex3 = tex2D(_Hatch3,i.uv) * i.hatchWeights1.x;
                fixed4 hatchTex4 = tex2D(_Hatch4,i.uv) * i.hatchWeights1.y;
                fixed4 hatchTex5 = tex2D(_Hatch5,i.uv) * i.hatchWeights1.z;

                fixed4 whiteColoor = fixed4(1,1,1,1) * (1-i.hatchWeights0.x-i.hatchWeights0.y-i.hatchWeights0.z-i.hatchWeights1.x-i.hatchWeights1.y-i.hatchWeights1.z);
                fixed4 hatchColor = hatchTex0 + hatchTex1 + hatchTex2 + hatchTex3 + hatchTex4 + hatchTex5 + whiteColoor;

                return fixed4(hatchColor.rgb*_Color.rgb,1.0);
            }

            ENDCG
        }
    }
    FallBack "Diffuse"
    
}