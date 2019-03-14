// 自制投影机
Shader "Volume 10/Projector/Customize Projector" {
    Properties {
        _MainTex("Main Tex",2D) = "white" {}
        _Color("Color",Color) = (1, 1, 1, 1)
    }
    SubShader {
        
        Tags { "RenderType"="Opaque" "Queue"="Geometry" }

        // 漫反射Pass
        Pass {

            Blend SrcAlpha OneMinusSrcAlpha

            Tags { "LightMode"="ForwardBase" }

            CGPROGRAM
            
            #include "Lighting.cginc"

            #pragma vertex vert
            #pragma fragment frag

            fixed4 _Color;

            struct a2v{
                float4 vertex : POSITION;
                float3 normal : NORMAL;
            };
            struct v2f{
                float4 pos : SV_POSITION;
                float3 worldNormal : TEXCOORD0;
                float3 worldPos : TEXCOORD1;                
            };

            v2f vert(a2v v){
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);

                o.worldPos = mul(unity_ObjectToWorld,v.vertex).xyz;
                o.worldNormal = UnityObjectToWorldNormal(v.normal);
                
                return o;
            }        

            fixed4 frag(v2f i) : SV_TARGET{
                fixed3 worldNormal = normalize(i.worldNormal);
                fixed3 worldLightDir = normalize(UnityWorldSpaceLightDir(i.worldPos));

                fixed3 diffuse = _Color.rgb * _LightColor0.rgb * max(0,dot(worldNormal,worldLightDir));

                return fixed4(diffuse,1.0);
            }

            ENDCG
        }
        
        // Projector的Pass
        Pass {

            Blend SrcAlpha OneMinusSrcAlpha

            CGPROGRAM            

            #include "UnityCG.cginc"

            #pragma vertex vert
            #pragma fragment frag

            // 投影机的VP矩阵
            float4x4 _ProjectorVPMatrix;
            sampler2D _MainTex;

            struct v2f{
                float4 pos : SV_POSITION;
                float4 uvDecal : TEXCOORD0;
                float4 uvFallOff : TEXCOORD1;
            };

            v2f vert(appdata_base v){
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);

                // 将当前顶点转换到投影机的裁剪空间
                // 构造MVP矩阵
                float4x4 decalMVP = mul(_ProjectorVPMatrix,unity_ObjectToWorld);

                // 在裁剪空间下顶点的坐标
                float4 decalProjectSpacePos = mul(decalMVP,v.vertex);

                // 根据顶点坐标获得当前顶点所在屏幕的位置(没有进行齐次除法的)
                o.uvDecal = ComputeScreenPos(decalProjectSpacePos);
                return o;
            }

            fixed4 frag(v2f i) : SV_TARGET{
                fixed4 decal = tex2D(_MainTex,i.uvDecal.xy/i.uvDecal.w);
                return decal;
            }

            ENDCG
        }
    }
    FallBack "Diffuse"
    
}