// 基于CubeMap模拟菲涅尔反射
Shader "Volume 05/Cube Map/Fresnel" {
    Properties {
        _Color("Color Tint",Color) = (1, 1, 1, 1)
        // 菲涅尔系数,用于控制菲涅尔反射的强度
        _FresnelScale("Fresnel Scale",Range(0,1)) = 0.5
        _CubeMap("Cube Map",Cube) = "_Skybox" {}
    }
    SubShader {
        Tags { "RenderType"="Opaque" "Queue"="Geometry" }
        Pass {
            Tags { "LightMode"="ForwardBase" }
            CGPROGRAM
            
            #include "UnityCG.cginc"
            #include "Lighting.cginc"

            #pragma vertex vert
            #pragma fragment frag

            fixed4 _Color;
            fixed _FresnelScale;
            samplerCUBE _CubeMap;

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
                o.worldNormal = UnityObjectToWorldNormal(v.normal);
                o.worldPos = mul(unity_ObjectToWorld,v.vertex);

                return o;
            }

            fixed4 frag(v2f i) : SV_TARGET{
                // 计算归一化法线/视角方向/光源方向
                fixed3 worldNormal = normalize(i.worldNormal);
                fixed3 worldViewDir = normalize(UnityWorldSpaceViewDir(i.worldPos));
                fixed3 worldLightDir = normalize(UnityWorldSpaceLightDir(i.worldPos));

                // 计算视角方向基于法线的反射方向
                float3 reflection = reflect(-worldViewDir,worldNormal);

                // 根据反射方向对CubeMap进行采样
                fixed3 refelctionColor = texCUBE(_CubeMap,reflection).rgb;

                // 计算菲涅尔系数
                fixed fresnel = _FresnelScale + (1-_FresnelScale)*pow(1-dot(worldViewDir,worldNormal),5);

                // 计算漫反射光照
                fixed3 diffuse = _LightColor0.rgb * _Color.rgb * max(0,dot(worldLightDir,worldNormal));

                fixed3 finalColor = lerp(diffuse,refelctionColor,saturate(fresnel));
                // fixed3 finalColor = (diffuse + refelctionColor)*fresnel;
                // fixed3 finalColor = diffuse + (refelctionColor*fresnel);

                return fixed4(finalColor,1.0);
            }

            ENDCG
        }
    }
    FallBack "Diffuse"
    
}