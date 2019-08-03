/*
    PBR渲染练习
*/
Shader "Volume 13/PBR/Custom PBR" {
    Properties {
        _Color("Color",Color) = (1, 1, 1, 1)
        _MainTex("Albedo",2D) = "white" {}
        // 光滑程度
        _Glossiness("Smoothness",Range(0.0,1.0)) = 0.5
        // 高光反射颜色
        _SpecularColor("Specular",Color) = (0.2, 0.2, 0.2, 1)
        // A通道控制材质粗糙度
        _SpecGlassMap("Specular (RGB) Smoothness(A)",2D) = "white" {}
        // 凹凸程度
        _BumpScale("Bump Scale",Float) = 1.0
        // 法线图
        _BumpMap("Normal Map",2D) = "bump" {}
        // 自发光颜色
        _EmissionColor("Color",Color) = (0, 0, 0, 1)
        _EmissionMap("Emission",2D) = "white" {}
    }
    SubShader {
        Tags { "RenderType"="Opaque" }
        LOD 300
        Pass {
            // 设置前向渲染BasePass
            Tags { "LightMode"="ForwardBase" }

            CGPROGRAM

            #include "Lighting.cginc"
            #include "UnityCG.cginc"
            #include "AutoLight.cginc"

            #pragma target 3.0

            #pragma multi_compile_fwdbase
            #pragma multi_compile_fog

            #pragma vertex vert
            #pragma fragment frag

            fixed4 _Color;
            sampler2D _MainTex;
            float4 _MainTex_ST;
            fixed _Glossiness;        
            sampler2D _SpecGlassMap;
            float _BumpScale;
            sampler2D _BumpMap;
            fixed4 _EmissionColor;
            sampler2D _EmissionMap;
            fixed4 _SpecularColor;

            struct v2f{
                float4 pos : SV_POSITION;
                float2 uv: TEXCOORD0;

                // 切线-世界变换矩阵
                float4 TtoW0 : TEXCOORD1;
                float4 TtoW1 : TEXCOORD2;
                float4 TtoW2 : TEXCOORD3;

                // 设置阴影
                SHADOW_COORDS(4)

                // Unity自带雾效
                UNITY_FOG_COORDS(5)
            };

            struct a2v{
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float4 tangent : TANGENT;
                float4 texcoord : TEXCOORD0;
            };

            // 迪士尼BRDF漫反射模型        
            inline half3 CustomDisneyDiffuseTerm(
                half NdotV,half NdotL,half LdotH,
                half roughness,half3 baseColor
                ){
                
                half fd90 = 0.5 + 2*LdotH * LdotH * roughness;

                half lightScatter = (1 + (fd90-1) * pow(1-NdotL,5));
                half viewScatter = (1 + (fd90-1) * pow(1-NdotV,5));

                return baseColor * UNITY_INV_PI * lightScatter * viewScatter;
            }

            // 高光反射中的可见性项计算
            inline half CustomSmithJointGGXVisibilityTerm(half NdotL,half NdotV,half roughness){
                half a2 = roughness * roughness;
                half lambdaV = NdotL * (NdotV * (1-a2) + a2);
                half lambdaL = NdotV * (NdotL * (1-a2) + a2);

                return 0.5f / (lambdaV + lambdaL + 1e-5f);
            }

            // 高光反射中的法线分布项计算
            inline half CustomGGXTerm(half NdotH,half roughness){
                half a2 = roughness*roughness;
                half d = (NdotH * a2 - NdotH) * NdotH + 1.0f;
                return UNITY_INV_PI * a2 / (d*d+1e-7f);
            }

            // 计算高光反射的菲涅尔项
            inline half3 CustomFresnelTerm(half3 c,half cosA){
                half t = pow(1-cosA,5);
                return c+(1-c)*t;
            }

            inline half3 CustomFresnelLerp(half3 c0, half3 c1, half cosA) {
                half t = pow(1 - cosA, 5);
                return lerp (c0, c1, t);
            }

            v2f vert(a2v v){
                v2f o;
                // 将模型空间内的顶点变换到裁剪空间中
                o.pos = UnityObjectToClipPos(v.vertex);
                // uv偏移
                o.uv = TRANSFORM_TEX(v.texcoord,_MainTex);

                float3 worldPos = mul(unity_ObjectToWorld,v.vertex).xyz;
                fixed3 worldNormal = normalize(UnityObjectToWorldNormal(v.normal));
                fixed3 worldTangent = normalize(UnityObjectToWorldDir(v.tangent));
                fixed3 worldBinormal = cross(worldNormal,worldTangent) * v.tangent.w;

                // 构建 切线-世界 变换矩阵
                o.TtoW0 = float4(worldTangent.x,worldBinormal.x,worldNormal.x,worldPos.x);
                o.TtoW1 = float4(worldTangent.y,worldBinormal.y,worldNormal.y,worldPos.y);
                o.TtoW2 = float4(worldTangent.z,worldBinormal.z,worldNormal.z,worldPos.z);

                TRANSFER_SHADOW(o);

                UNITY_TRANSFER_FOG(o,o.pos);

                return o;
            }

            fixed4 frag(v2f i) : SV_TARGET{
                // 材质粗糙度计算            
                half4 specGloss = tex2D(_SpecGlassMap,i.uv);
                specGloss.a *= _Glossiness;
                half3 specColor = specGloss.rgb * _SpecularColor.rgb;
                half roughness = 1 - specGloss.a;

                half oneMinusReflectivity = 1 - max( max(specColor.r,specColor.g) , specColor.b );
            
                // 漫反射颜色
                half3 diffColor = _Color.rgb * tex2D(_MainTex,i.uv).rgb * oneMinusReflectivity;

                // 计算法线
                half3 normalTangent = UnpackNormal(tex2D(_BumpMap,i.uv));
                normalTangent.xy *= _BumpScale;
                normalTangent.z = sqrt(1.0 - saturate(dot(normalTangent.xy,normalTangent.xy)));
                half3 normalWorld = normalize(
                    half3(dot(i.TtoW0.xyz,normalTangent),
                    dot(i.TtoW1.xyz,normalTangent),
                    dot(i.TtoW2.xyz,normalTangent))
                    );   

                float3 worldPos = float3(i.TtoW0.w,i.TtoW1.w,i.TtoW2.w);
                half3 lightDir = normalize( UnityWorldSpaceLightDir(worldPos) );
                half3 viewDir = normalize( UnityWorldSpaceViewDir(worldPos) );

                half3 reflDir = reflect(-viewDir,normalWorld);

                UNITY_LIGHT_ATTENUATION(atten,i,worldPos);


                // 计算BRDF光照模型
                half halfDir = normalize(lightDir+viewDir);
                // NdotV,用于计算BRDF高光反射项
                half nv = saturate(dot(normalWorld,viewDir));
                // NdotL，即光源因为入射角产生的衰减
                half nl = saturate(dot(normalWorld,lightDir));
                // 向量h表示微面元的法线,只有当微面元的法线n=h时,入射光才会反射到观察方向
                half nh = saturate(dot(normalWorld,halfDir));
                half lv = saturate(dot(lightDir,viewDir));
                half lh = saturate(dot(lightDir,halfDir));

                // 计算BRDF的漫反射项
                half3 diffuseTerm = CustomDisneyDiffuseTerm(nv,nl,lh,roughness,diffColor);


                // 计算BRDF的高光反射项

                // 阴影-遮挡项(也叫可见性项),表示入射光线被遮挡和反射到观察方向的光线被遮挡的比例
                half V = CustomSmithJointGGXVisibilityTerm(nl,nv,roughness);

                // 法线分布函数,计算有多少微面元的法线为h(即可以反射光线到观察方向)
                half D = CustomGGXTerm(nh,roughness*roughness);

                // 菲涅尔项,计算有多少入射光线会恰好反射到观察方向上
                half F = CustomFresnelTerm(specColor,lh);

                // 计算高光反射项
                half3 specularTerm = F*V*D;

                // 计算自发光项
                half3 emisstionTerm = tex2D(_EmissionMap,i.uv).rgb * _EmissionColor.rgb;

                // 计算基于图像的光照部分(IBL)
                half perceptualRoughness = roughness *  (1.7 - 0.7 * roughness);
                half mip = perceptualRoughness * 6;
                half4 envMap = UNITY_SAMPLE_TEXCUBE_LOD(unity_SpecCube0,reflDir,mip);
                half grazingTerm = saturate((1 - roughness) + (1-oneMinusReflectivity));
                half surfaceReduction = 1.0 / (roughness*roughness+1.0);
                half3 indirectSpecular = surfaceReduction * envMap.rgb * CustomFresnelLerp(specColor,grazingTerm,nv);

                // 计算渲染方程的解
                half3 color = emisstionTerm + UNITY_PI * (diffuseTerm+specularTerm) * _LightColor0.rgb * nl * atten + indirectSpecular;

                UNITY_APPLY_FOG(i.fogCoord,c.rgb);

                return half4(color,1); 
            }

            ENDCG
        }
    }
    FallBack "Diffuse"
    
}
