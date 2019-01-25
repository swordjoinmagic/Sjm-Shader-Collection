/*
    渐变纹理
*/
Shader "Volume 02/Texture/Ramp Texture" {
    Properties {
        // 用于控制材质整体颜色
        _Color("Color Tint",Color) = (1, 1, 1, 1)
        // 渐变纹理
        _RampTex("Ramp Tex",2D) = "white" {}
        // 高光反射颜色
        _Specular("Specular Color",Color) = (1, 1, 1, 1)
        // 光泽度
        _Gloss("_Gloss",Range(8.0,256)) = 20
    }
    SubShader {

        Tags{ "RenderType" = "Opaque" "Queue" = "Geometry"  }

        Pass {
            Tags{ "LightMode" = "Forwardbase" }

            CGPROGRAM

            #include "UnityCg.cginc"
            #include "Lighting.cginc"

            #pragma vertex vert
            #pragma fragment frag

            fixed4 _Color;
            sampler2D _RampTex;
            float4 _RampTex_ST;
            fixed4 _Specular;
            float _Gloss;

            struct a2v{
                float4 vertex : POSITION;
                float4 texcoord : TEXCOORD0;
                float3 normal : NORMAL;
            };
            struct v2f{
                float4 pos : SV_POSITION;
                float3 worldPos : TEXCOORD0;
                float2 uv : TEXCOORD1;
                float3 worldNormal : TEXCOORD2;
            };

            v2f vert(a2v v){
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);

                // 对贴图进行位移缩放处理
                o.uv = TRANSFORM_TEX(v.texcoord,_RampTex);
                // 世界空间下的顶点位置
                o.worldPos = mul(unity_ObjectToWorld,v.vertex);
                // 世界空间下的法线位置
                o.worldNormal = UnityObjectToWorldNormal(v.normal);

                return o;
            }

            fixed4 frag(v2f i) : SV_TARGET{
                // 获得归一化的世界空间下的法线
                fixed3 worldNormal = normalize(i.worldNormal);
                // 获得光源方向
                fixed3 worldLightDir = normalize(UnityWorldSpaceLightDir(i.worldPos));
                // 获得环境光源
                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;

                // 计算半兰伯特
                fixed halfLambert = 0.5 * dot(worldNormal,worldLightDir) + 0.5;

                // 计算漫反射颜色
                fixed3 diffuseColor = tex2D(_RampTex,fixed2(halfLambert,halfLambert)).rgb * _Color.rgb * _LightColor0.rgb;

                // 获得视角方向
                fixed3 viewDir = normalize(UnityWorldSpaceViewDir(i.worldPos));
                
                fixed halfDir = normalize(worldLightDir+viewDir);

                // 计算高光反射
                fixed3 specular = _LightColor0.rgb * _Specular.rgb * pow(max(0,dot(worldNormal,halfDir)),_Gloss);

                return fixed4(ambient+diffuseColor+specular,1.0);
            }

            ENDCG

        }
    }
    FallBack "Diffuse"
    
}