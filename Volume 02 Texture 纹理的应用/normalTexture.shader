// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'

/*
    简单运用法线映射,即,物体根据对应的法线贴图来进行光照计算
*/
Shader "Volume 02/Texture/Normal Texture"{
    Properties{
        // 主纹理
        _MainTex("Main Tex",2D) = "white" {}
        // 法线贴图
        _BumpTex("Bump Tex",2D) = "bump" {}
        // 物体的颜色控制
        _Color("Color Tint",Color) = (1, 1, 1, 1)
        // 高光反射颜色控制
        _Specular("Specular",Color) = (1, 1, 1, 1)
        // 高光反射光泽度
        _Gloss("Gloss",Range(8.0,256)) = 20
        // 凹凸程度
        _BumpScale("BumpScale",Float) = 1.0
    }
    SubShader{
        Tags { "RenderType"="Opaque" "Queue"="Geometry" }
        Pass {

            // 设置渲染路径
            Tags { "LightMode" = "ForwardBase" }

            CGPROGRAM
            
            #pragma vertex vert
            #pragma fragment frag

            #include "Lighting.cginc"

            struct a2v{
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float4 tangent : TANGENT;
                float4 texcoord : TEXCOORD0;
            };
            struct v2f{
                float4 pos : SV_POSITION;   // 裁剪空间下的顶点坐标

                //===========================
                // 切线空间 -- 世界空间 变换矩阵
                float4 TtoW0 : TEXCOORD0;   // 变换矩阵第一行,w分量存放worldPos.x
                float4 TtoW1 : TEXCOORD1;   // 变换矩阵第一行,w分量存放worldPos.y
                float4 TtoW2 : TEXCOORD2;   // 变换矩阵第一行,w分量存放worldPos.z

                //============================
                // uv坐标
                float2 uv : TEXCOORD3;
                float2 bump_uv : TEXCOORD4;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;     // 主纹理的缩放和位移
            sampler2D _BumpTex;
            float4 _BumpTex_ST;     // 法线贴图的缩放和位移
            fixed4 _Color;
            fixed4 _Specular;
            float _Gloss;
            float _BumpScale;

            v2f vert(a2v v){
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);

                // 世界坐标下的顶点位置,用于光照计算
                // float3 worldPos = UnityObjectToWorldDir(v.vertex);
                float3 worldPos = mul(unity_ObjectToWorld,v.vertex).xyz;

                // 获得世界坐标下的法线(用于构建变换矩阵,无需归一化)
                float3 worldNormal = UnityObjectToWorldNormal(v.normal);
                // 获得世界坐标下的切线(用于构建变换矩阵,无需归一化)
                float3 worldTangent = UnityObjectToWorldDir(v.tangent.xyz);
                // 根据法线和切线的叉积,计算副切线在世界坐标下的位置
                float3 worldBinNormal = cross(worldNormal,worldTangent) * v.tangent.w;

                //===========================
                // 构建变换矩阵,按列摆放世界坐标下的切线空间的x,y,z轴
                o.TtoW0 = float4(worldTangent.x,worldBinNormal.x,worldNormal.x,worldPos.x);
                o.TtoW1 = float4(worldTangent.y,worldBinNormal.y,worldNormal.y,worldPos.y);
                o.TtoW2 = float4(worldTangent.z,worldBinNormal.z,worldNormal.z,worldPos.z);

                //===================================
                // uv坐标
                o.uv = TRANSFORM_TEX(v.texcoord,_MainTex);
                o.bump_uv = TRANSFORM_TEX(v.texcoord,_BumpTex);            

                return o;
            }

            fixed4 frag(v2f i) : SV_TARGET{
                // 解析世界坐标
                float3 worldPos = float3(i.TtoW0.w,i.TtoW1.w,i.TtoW2.w);

                // 获得切线空间下的法线
                float3 tangentNormal = UnpackNormal(tex2D(_BumpTex,i.bump_uv));
                // 根据凹凸程度缩放法线
                tangentNormal.xy *= _BumpScale;
                tangentNormal.z = sqrt(1.0 - saturate(dot(tangentNormal.xy,tangentNormal.xy)));
                // 将法线变换到世界坐标空间下
                fixed3 bump = normalize(half3( dot(i.TtoW0.xyz,tangentNormal),dot(i.TtoW1.xyz,tangentNormal),dot(i.TtoW2.xyz,tangentNormal) ));

                // 获得光源方向
                fixed3 worldLightDir = normalize(UnityWorldSpaceLightDir(worldPos));
                // 对主纹理进行采样
                fixed3 albedo = tex2D(_MainTex,i.uv).rgb * _Color.rgb;
                // 计算漫反射光照
                fixed3 diffuse = _LightColor0.rgb * albedo * max(0,dot(worldLightDir,bump));
                // 计算环境光
                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.rgb * albedo;
                // 计算归一化的观察方向
                fixed3 worldViewDir = normalize(UnityWorldSpaceViewDir(worldPos));
                // 计算Blinn模型的half变量
                fixed3 halfDir = normalize(worldLightDir + worldViewDir);
                // 计算高光反射
                fixed3 specular = _LightColor0.rgb * _Specular.rgb * pow(max(0,dot(bump,halfDir)),_Gloss);

                // 着色
                return fixed4(specular + ambient + diffuse , 1.0);
            }

            ENDCG
        }
    }
    Fallback "Diffuse"
}