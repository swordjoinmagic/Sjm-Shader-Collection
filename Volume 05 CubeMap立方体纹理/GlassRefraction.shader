// 使用CubeMap和GrapPass制作玻璃效果
Shader "Volume 05/Cube Map/GlassRefraction" {
    Properties {
        _MainTex("Main Texture",2D) = "white" {}
        // 法线纹理
        _BumpMap("Bump Map",2D) = "bump" {}
        // 立方体纹理,用于反射
        _CubeMap("Cube Map",Cube) = "_Skybox" {}
        // 折射时的扰动程度
        _Distorition("Distortion",Range(0,100)) = 10
        // 折射程度
        _RefracAmount("Refraction Amount",Range(0,1)) = 1.0
    }
    SubShader {
        // 因为要使用GrapPass,所以必须在所有不透明物体之后渲染
        Tags{ "Queue"="Transparent" "RenderType"="Opaque"}

        // GrabPass,用于对当前屏幕图像进行截图,
        // 并把图片输出到一张纹理中去
        GrabPass{ "_RefractionTex" }

        Pass {

            Tags{ "LightMode" = "ForwardBase"}

            CGPROGRAM
            
            #include "UnityCG.cginc"

            #pragma vertex vert
            #pragma fragment frag

            sampler2D _MainTex;
            float4 _MainTex_ST;
            sampler2D _BumpMap;
            float4 _BumpMap_ST;
            samplerCUBE _CubeMap;
            float _Distorition;
            fixed _RefracAmount;
            sampler2D _RefractionTex;
            float4 _RefractionTex_TexelSize;

            struct a2v{
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float4 tangent : TANGENT;
                float2 texcoord : TEXCOORD0;
            };

            struct v2f{
                float4 pos : SV_POSITION;
                
                // 切线-世界 变换矩阵构造,w分量存worldPos
                float4 TtoW0 : TEXCOORD0;
                float4 TtoW1 : TEXCOORD1;
                float4 TtoW2 : TEXCOORD2;

                // 对主纹理和法线纹理进行采样的uv,xy:主纹理,zw:法线纹理
                float4 uv : TEXCOORD3;

                // 当前顶点在整个屏幕中的位置,用于对GrabPass得到的屏幕图像进行采样,该坐标未进行齐次除法
                float4 screenPos : TEXCOORD4;
            };

            v2f vert(a2v v){
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);

                float3 worldPos = mul(unity_ObjectToWorld,v.vertex).xyz;
                float3 worldNormal = UnityObjectToWorldNormal(v.normal);
                float3 worldTangent = UnityObjectToWorldDir(v.tangent);
                // 计算世界坐标下的副切线(根据法线与切线的叉积得到)(根据切线的w分量确定副切线的方向)
                float3 worldBinTangent = cross(worldNormal,worldTangent) * v.tangent.w;

                // 构造变换矩阵
                o.TtoW0 = float4(worldTangent.x,worldBinTangent.x,worldNormal.x,worldPos.x);
                o.TtoW1 = float4(worldTangent.y,worldBinTangent.y,worldNormal.y,worldPos.y);
                o.TtoW2 = float4(worldTangent.z,worldBinTangent.z,worldNormal.z,worldPos.z);

                // 获得主纹理和法线纹理的采样坐标
                o.uv.xy = TRANSFORM_TEX(v.texcoord,_MainTex);
                o.uv.zw = TRANSFORM_TEX(v.texcoord,_BumpMap);

                // 得到当前顶点在整个屏幕中的位置,输入参数是裁剪空间中的顶点坐标
                o.screenPos = ComputeGrabScreenPos(o.pos);

                return o;
            }

            fixed4 frag(v2f i) : SV_TARGET{
                float3 worldPos = float3(i.TtoW0.w,i.TtoW1.w,i.TtoW2.w);
                
                // 取出法线纹理中的法线(此时法线在切线空间中)
                float3 normal = UnpackNormal(tex2D(_BumpMap,i.uv.zw));

                // 计算ScreenPos因为折射产生的偏移,通过切线空间下的法线来计算
                float2 offset = normal.xy * _Distorition * _RefractionTex_TexelSize.xy;
                i.screenPos.xy = i.screenPos.xy+offset;
                // 计算折射产生的颜色
                fixed3 refractColor = tex2D(_RefractionTex,i.screenPos.xy/i.screenPos.w).rgb;

                // 将法线变换到世界坐标空间下,并将其归一化
                fixed3 worldNormal = normalize(float3(dot(normal,i.TtoW0.xyz),dot(normal,i.TtoW1.xyz),dot(normal,i.TtoW2.xyz)));

                // 计算视角方向
                fixed3 worldViewDir = normalize(UnityWorldSpaceViewDir(worldPos));
                // 计算光源方向
                fixed3 worldLightDir = normalize(UnityWorldSpaceLightDir(worldPos));
                // 计算视角方向关于法线的反射方向
                float3 reflection = reflect(-worldViewDir,worldNormal);

                // 计算反射产生的颜色
                fixed3 reflectColor = texCUBE(_CubeMap,reflection).rgb;

                fixed3 texColor = tex2D(_MainTex,i.uv.xy);

                reflectColor *= texColor;

                fixed3 finalColor = lerp(reflectColor,refractColor*texColor,_RefracAmount);
                // fixed3 finalColor = reflectColor * refractColor * _RefracAmount;

                return fixed4(finalColor,1.0);
            }

            ENDCG
        }
    }
    FallBack "Diffuse"
    
}