// Upgrade NOTE: replaced '_LightMatrix0' with 'unity_WorldToLight'

// Upgrade NOTE: replaced '_LightMatrix0' with 'unity_WorldToLight'


// 前向渲染
Shader "Volume 03/Forward Render/Forward Rendering" {
    Properties {
        _Color("Color Tint",Color) = (1, 1, 1, 1)
        _Specular("Specular Color",Color) = (1, 1, 1, 1)
        _Gloss("Gloss",Range(8.0,256)) = 25
    }
    SubShader {
        Tags { "RenderType"="Opaque" "Queue"="Geometry" }

        // BasePass
        Pass {
            Tags { "LightMode"="ForwardBase" }
            CGPROGRAM
            
            #pragma multi_compile_fwdbase	

            #include "UnityCG.cginc"
            #include "Lighting.cginc"
            #include "AutoLight.cginc"

            #pragma vertex vert
            #pragma fragment frag

            fixed4 _Color;
            fixed4 _Specular;
            float _Gloss;

            struct a2v{
                float4 vertex : POSITION;
                float3 normal : NORMAL;
            };
            struct v2f{
                float4 pos : SV_POSITION;
                float3 worldNormal : TEXCOORD0;
                float3 worldPos : TEXCOORD1;

                // 存储阴影映射纹理的数据结构
                SHADOW_COORDS(2)
            };

            v2f vert(a2v v){
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.worldNormal = UnityObjectToWorldNormal(v.normal);
                o.worldPos = mul(unity_ObjectToWorld,v.vertex).xyz;

                // 填充阴影映射纹理
                TRANSFER_SHADOW(o);

                return o;
            }

            fixed4 frag(v2f i) : SV_TARGET{
                fixed3 worldNormal = normalize(i.worldNormal);
                fixed3 worldLightDir = normalize(UnityWorldSpaceLightDir(i.worldPos));
                
                fixed4 diffuse = _Color * _LightColor0 * max(0,dot(worldLightDir,worldNormal));

                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.rgb;

                fixed3 worldViewDir = normalize(UnityWorldSpaceViewDir(i.worldPos));

                fixed3 halfDir = normalize(worldViewDir+worldLightDir);

                fixed4 specular = _LightColor0 * _Specular * pow(max(0,dot(worldNormal,halfDir)),_Gloss);

                // 对阴影映射纹理进行采样
                fixed shadow = SHADOW_ATTENUATION(i);

                return fixed4(ambient+diffuse.rgb*shadow+specular.rgb,1);
            }

            ENDCG
        }

        // Additional Pass
        Pass {
            Tags { "LightMode" = "ForwardAdd" }

            Blend One One

            CGPROGRAM
            
            #include "UnityCG.cginc"
            #include "Lighting.cginc"
            #include "AutoLight.cginc"

            #pragma multi_compile_fwdadd

            #pragma vertex vert
            #pragma fragment frag

            fixed4 _Color;
            fixed4 _Specular;
            float _Gloss;

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
                o.worldPos = mul(unity_ObjectToWorld,v.vertex).xyz;

                return o;
            }

            fixed4 frag(v2f i) : SV_TARGET{
                fixed3 worldNormal = normalize(i.worldNormal);
                // fixed3 worldLightDir = normalize(UnityWorldSpaceLightDir(i.worldPos));
                
                #ifdef USING_DIRECTIONAL_LIGHT
					fixed3 worldLightDir = normalize(_WorldSpaceLightPos0.xyz);
				#else
					fixed3 worldLightDir = normalize(_WorldSpaceLightPos0.xyz - i.worldPos.xyz);
				#endif
                
                fixed4 diffuse = _Color * _LightColor0 * max(0,dot(worldLightDir,worldNormal));

				#ifdef USING_DIRECTIONAL_LIGHT
					fixed atten = 1.0;
				#else
					#if defined (POINT)
				        float3 lightCoord = mul(unity_WorldToLight, float4(i.worldPos, 1)).xyz;
				        fixed atten = tex2D(_LightTexture0, dot(lightCoord, lightCoord).rr).UNITY_ATTEN_CHANNEL;
				    #elif defined (SPOT)
				        float4 lightCoord = mul(unity_WorldToLight, float4(i.worldPos, 1));
				        fixed atten = (lightCoord.z > 0) * tex2D(_LightTexture0, lightCoord.xy / lightCoord.w + 0.5).w * tex2D(_LightTextureB0, dot(lightCoord, lightCoord).rr).UNITY_ATTEN_CHANNEL;
				    #else
				        fixed atten = 1.0;
				    #endif
				#endif
                
                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.rgb;

                // fixed3 worldViewDir = normalize(UnityWorldSpaceViewDir(i.worldPos));

                fixed3 worldViewDir = normalize(_WorldSpaceCameraPos.xyz - i.worldPos.xyz);

                fixed3 halfDir = normalize(worldViewDir+worldLightDir);

                fixed4 specular = _LightColor0 * _Specular * pow(max(0,dot(worldNormal,halfDir)),_Gloss);
                
                return fixed4((diffuse.rgb+specular.rgb)*atten,1);
            }

            ENDCG
        }
    }
    FallBack "Diffuse"
    
    
}