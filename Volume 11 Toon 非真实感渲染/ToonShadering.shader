/**
    卡通化渲染，基本步骤是：
    1. 给单位添加轮廓线
    2. 给单位添加突变的高光，即不是渐变的，而是根据一个阈值，
    当前像素辐照度大于该阈值时，表现出高光，否则不表现
*/
Shader "Volume 11/Toon/ToonShadering" {
    Properties {
        // 主纹理
        _MainTex("_MainTex",2D) = "white" {}
        // 高光阈值
        _Threshold("Threshold",Float) = 0.5
        // 渐变纹理，用于控制漫反射系数
        _RampTex("Ramp Texture",2D) = "white" {}
        // 漫反射颜色
        _Color("Color",Color) = (1, 1, 1, 1)
        // 高光反射颜色
        _Specular("Spcular Color",Color) = (1, 1, 1, 1)
        // 描边颜色
        _OutlineColor("OutLineColor",Color) = (0, 0, 0, 1)
        // 描边长度
        _OutlineWidth("outline Width",Float) = 1.0
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

        // 正常输出颜色的Pass
        Pass {
            Tags { "LightMode"="ForwardBase" }

            // 剔除背面
            Cull Back

            CGPROGRAM
            
            #include "UnityCG.cginc"
            #include "Lighting.cginc"

            #pragma vertex vert
            #pragma fragment frag            

            sampler2D _RampTex;
            sampler2D _MainTex;
            fixed4 _Color;
            fixed4 _Specular;         
            float _Threshold;   

            struct a2v{
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float2 texcoord : TEXCOORD0;
            };

            struct v2f{
                float4 pos : SV_POSITION;
                float3 worldNormal : TEXCOORD0;
                float3 worldPos : TEXCOORD1;
                float2 uv : TEXCOORD2;
            };

            v2f vert(a2v v){
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);

                o.worldNormal = UnityObjectToWorldNormal(v.normal);
                o.worldPos = mul(unity_ObjectToWorld,v.vertex);
                o.uv = v.texcoord;

                return o;
            }

            fixed4 frag(v2f i) : SV_TARGET{
                fixed3 worldNormal = normalize(i.worldNormal);
                fixed3 worldLightDir = normalize(UnityWorldSpaceLightDir(i.worldPos));
                fixed3 worldViewDir = normalize(UnityWorldSpaceViewDir(i.worldPos));

                // 计算半兰伯特系数
                fixed halfLabert = 0.5 * dot(worldNormal,worldLightDir) + 0.5;

                // 根据半兰伯特系数对渐变纹理进行采样
                fixed3 ramp = tex2D(_RampTex,fixed2(halfLabert,halfLabert)).rgb;

                // 反射系数
                fixed3 albedo = tex2D(_MainTex,i.uv).rgb * _Color.rgb * ramp;
                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.rgb * albedo;

                // 漫反射光照
                fixed3 diffuse = albedo * _LightColor0.rgb;

                // 高光反射
                // fixed3 specularColor = _Specular.rgb * step(_Threshold,specular);

                // 计算高光反射
                fixed worldHalfDir = normalize(worldLightDir+worldViewDir);
                
                float specular = dot(worldHalfDir,worldNormal);

                fixed w = fwidth(specular) * 2.0;
				fixed3 specularColor = _Specular.rgb * lerp(0, 1, smoothstep(-w, w, specular + _Threshold - 1)) * step(0.0001, _Threshold);

                return fixed4(diffuse+ambient+specularColor,1.0);

            }

            ENDCG
        }
    }
    FallBack "Diffuse"
    
}