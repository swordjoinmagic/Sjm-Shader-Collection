// 透明度混合
Shader "Volume 03/Alpha/Alpha Blend" {
    Properties {
        _MainTex("Main Texture",2D) = "white" {}
        _Color("Color Tint",Color) = (1, 1, 1, 1)        
        // 透明度
        _Alpha("Alpha Value",Range(0,1)) = 0.5
    }
    SubShader {
        Tags { "RenderType"="Transparent" "Queue"="Transparent" "IgnoreProjector"="True" }

        // 关闭深度写入
        ZWrite Off
        // 根据透明度进行混合
        Blend SrcAlpha OneMinusSrcAlpha

        Pass {
            // 设置渲染路径
            Tags { "LightMode" = "ForwardBase" }
            
            CGPROGRAM
            
            #include "UnityCG.cginc"
            #include "Lighting.cginc"

            #pragma vertex vert
            #pragma fragment frag

            sampler2D _MainTex;
            float4 _MainTex_ST;
            fixed4 _Color;
            fixed _Alpha;

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
                o.uv = TRANSFORM_TEX(v.texcoord,_MainTex);
                return o;
            }

            fixed4 frag(v2f i) : SV_TARGET{
                // 归一化法线
                fixed3 worldNormal = normalize(i.worldNormal);
                // 归一化光源方向
                fixed3 worldLightDir = normalize(UnityWorldSpaceLightDir(i.worldPos));

                // 计算反射率
                fixed4 albedo = _Color * tex2D(_MainTex,i.uv);

                // 计算漫反射光照
                fixed4 diffuse = _LightColor0 * albedo * max(0,dot(worldLightDir,worldNormal));

                return fixed4(diffuse.rgb,_Alpha);
            }

            ENDCG
        }
    }
    FallBack "Diffuse"
    
}