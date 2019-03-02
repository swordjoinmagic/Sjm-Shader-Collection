// 基于CubeMap实现反射效果
Shader "Volume 05/Cube Map/Reflection" {
    Properties {
        _Color("Color Tint",Color) = (1, 1, 1, 1)
        _ReflectColor("Reflection Color",Color) = (1, 1, 1, 1)
        // 反射程度
        _ReflectAmount("Reflection Amount",Range(0,1)) = 1
        _CubeMap("Cube Map",Cube) = "_Skybox" {}
    }
    SubShader {
        Tags{ "Queue"="Geometry" "RenderType"="Opaque" }
        Pass {
            Tags{ "LightMode" = "ForwardBase" }
            CGPROGRAM
            
            #include "UnityCG.cginc"
            #include "Lighting.cginc"

            #pragma vertex vert
            #pragma fragment frag

            fixed4 _Color;
            fixed4 _ReflectColor;
            fixed _ReflectAmount;
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
                // 归一化法线/视角方向
                fixed3 worldNormal = normalize(i.worldNormal);
                fixed3 worldViewDir = normalize(UnityWorldSpaceViewDir(i.worldPos));

                // 光源方向
                fixed3 worldLightDir = normalize(UnityWorldSpaceLightDir(i.worldPos));

                // 计算反射方向
                float3 reflection = reflect(-worldViewDir,worldNormal);

                // 根据反射方向对CubeMap进行采样
                fixed4 color = texCUBE(_CubeMap,reflection) * _ReflectColor;

                // 计算漫反射
                fixed4 diffuse = _LightColor0 * _Color * max(0,dot(worldLightDir,worldNormal));

                fixed3 finalColor = lerp(diffuse.rgb,color.rgb,_ReflectAmount);
                
                return fixed4(finalColor,1.0);
            }

            ENDCG
        }
    }
    FallBack "Diffuse"
    
}