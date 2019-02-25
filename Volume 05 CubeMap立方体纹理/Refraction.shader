// 基于CubeMap实现折射效果
Shader "Volume 05/Cube Map/Refraction" {
    Properties {
        _Color("Color Tint",Color) = (1, 1, 1, 1)
        _RefractColor("Refraction Color",Color) = (1, 1, 1, 1)
        // 折射程度
        _RefractAmount("Refraction Amount",Range(0,1)) = 1
        //  入射光线和折射介质的透射比
        _RefractRatio("Refraction Ratio",Range(0.1,1)) = 0.5
        _CubeMap("Cube Map",Cube) = "_Skybox" {}
    }
    SubShader {

        Tags{ "RenderType"="Opaque" "Queue"="Geometry" }

        Pass {
            Tags{"LightMode" = "ForwardBase"}

            CGPROGRAM
            
            #include "UnityCG.cginc"
            #include "Lighting.cginc"

            #pragma vertex vert
            #pragma fragment frag

            fixed4 _Color;
            fixed4 _RefractColor;
            fixed _RefractAmount;
            fixed _RefractRatio;
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
                // 获得归一化的法线/视角方向
                fixed3 worldNormal = normalize(i.worldNormal);
                fixed3 worldViewDir = normalize(UnityWorldSpaceViewDir(i.worldPos));

                // 计算折射方向
                float3 refraction = refract(-worldViewDir,worldNormal,_RefractRatio);
                // 根据折射方向对cubeMap进行采样
                fixed3 refractionColor = texCUBE(_CubeMap,refraction).rgb * _RefractColor.rgb;

                fixed3 worldLightDir = normalize(UnityWorldSpaceLightDir(i.worldPos));

                // 计算漫反射光照
                fixed3 diffuse = _Color.rgb * _LightColor0.rgb * max(0,dot(worldLightDir,worldNormal));

                fixed3 finalColor = lerp(diffuse,refractionColor,_RefractAmount);

                return fixed4(finalColor,1.0);
            }

            ENDCG
        }
    }
    FallBack "Diffuse"
    
}