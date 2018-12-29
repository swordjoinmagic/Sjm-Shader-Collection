Shader "Volume 01/Diffuse/Simple Specular Per Frag" {
    Properties {
        // 漫反射材质颜色
        _Diffuse("Diffuse Color",Color) = (1, 1, 1, 1)
        // 高光反射材质颜色
        _Specular("Specular Color",Color) = (1, 1, 1, 1)
        // 光泽度
        _Gloss("Gloss",Range(8.0,256)) = 20
    }
    SubShader {

        Tags { "RenderType" = "Opaque" "Queue"="Geometry"  }

        Pass {
            Tags { "LightMode" = "ForwardBase" }
            CGPROGRAM
            
            #pragma vertex vert
            #pragma fragment frag

            #include "Lighting.cginc"

            fixed4 _Diffuse;
            fixed4 _Specular;
            float _Gloss;

            struct a2v{
                float4 vertex : POSITION;
                float3 normal : NORMAL;
            };
            struct v2f{
                float4 pos : SV_POSITION;
                float3 worldPos : TEXCOORD0;
                float3 worldNormal : TEXCOORD1;
            };

            v2f vert(a2v v){
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);

                o.worldPos = UnityObjectToWorldDir(v.vertex).xyz;
                o.worldNormal = UnityObjectToWorldNormal(v.normal);

                return o;
            }

            fixed4 frag(v2f i):SV_TARGET{
                // 归一化法线与光源方向
                fixed3 worldNormal = normalize(i.worldNormal);
                fixed3 worldLightDir = normalize(UnityWorldSpaceLightDir(i.worldPos));

                // 环境光
                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.rgb;

                // 获得观察方向
                fixed3 worldViewDir = normalize(UnityWorldToViewPos(i.worldPos));

                fixed3 halfDir = normalize(worldViewDir+worldLightDir);

                // 计算漫反射光照
                fixed3 diffuse = _LightColor0.rgb * _Diffuse.rgb * max(0,dot(worldNormal,worldLightDir));

                // 计算高光反射
                fixed3 specular = _LightColor0.rgb * _Specular.rgb * pow(max(0,dot(worldNormal,halfDir)),_Gloss);
 
                return fixed4(diffuse + specular + ambient,1.0);   
            }

            ENDCG
        }
    }
    FallBack "Diffuse"
    
}