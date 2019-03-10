// 透明度测试
Shader "Volume 03/Alpha/Alpha Test" {
    Properties {
        _Color("Color",Color) = (1, 1, 1, 1)
        _MainTex("Main Texture",2D) = "white" {}
        _CutoOff("Alpha CutoOff",Range(0,1)) = 0.5

    }
    SubShader {
        Tags { "Queue"="AlphaTest" "RenderType"="TransparentCutout" }

        // 双面渲染
        Cull Off

        Pass {
            Tags { "LightMode" = "ForwardBase" }
            CGPROGRAM
            
            #include "UnityCG.cginc"
            #include "Lighting.cginc"

            #pragma vertex vert
            #pragma fragment frag

            fixed4 _Color;
            sampler2D _MainTex;
            float4 _MainTex_ST;
            fixed _CutoOff;

            struct a2v{
                float4 vertex : POSITION;
                float2 texcoord : TEXCOORD0;
                float3 normal : NORMAL;
            };
            struct v2f{
                float4 pos : SV_POSITION;
                float2 uv : TEXCOORD0;
                float3 worldNormal : TEXCOORD1;
                float3 worldPos : TEXCOORD2;
            };

            v2f vert(a2v i){
                v2f o;

                o.pos = UnityObjectToClipPos(i.vertex);
                o.uv = TRANSFORM_TEX(i.texcoord,_MainTex);
                o.worldNormal = UnityObjectToWorldNormal(i.normal);
                o.worldPos = mul(unity_ObjectToWorld,i.vertex);

                return o;
            }

            fixed4 frag(v2f i) : SV_TARGET{
                // 归一化法线
                fixed3 worldNormal = normalize(i.worldNormal);
                // 获得光源方向
                fixed3 worldLightDir = normalize(UnityWorldSpaceLightDir(i.worldPos));
                // 采样纹理
                fixed4 albedo = tex2D(_MainTex,i.uv) * _Color;

                // 根据图片的透明度进行透明度测试,图片透明度大于阈值则不进行裁剪
                clip(albedo.a - _CutoOff);

                // 计算漫反射光照
                fixed4 diffuse = albedo * _LightColor0 * max(0,dot(worldNormal,worldLightDir));

                return diffuse;
            }

            ENDCG
        }
    }
    FallBack "Diffuse"
    
}