/*
    简单运用纹理映射,也就是将一张纹理贴在物体上
*/
Shader "Volume 02/Texture/Single Texture" {
    Properties {
        // 主纹理
        _MainTex("Main Tex",2D) = "white" {}
        // 漫反射材质颜色
        _Diffuse("Diffuse Color",Color) = (1, 1, 1, 1)
        // 高光反射材质颜色
        _Specular("Specular Color",Color) = (1, 1, 1, 1)
        // 高光反射光泽度
        _Gloss("Gloss",Range(8.0,256)) = 20
    }
    SubShader {
        Tags { "RenderType"="Opaque" "Queue" = "Geometry" }
        Pass {
            // 设置渲染路径为前向渲染(使Unity正确填充光照变量)
            Tags { "LightMode" = "ForwardBase" }
            CGPROGRAM
            
            #pragma vertex vert
            #pragma fragment frag

            #include "Lighting.cginc"

            struct a2v{
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float4 texcoord : TEXCOORD;                
            };
            struct v2f{
                float4 pos : SV_POSITION;
                float2 uv : TEXCOORD0;
                float3 worldNormal : TEXCOORD1;
                float3 worldPos : TEXCOORD2;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;     // Scale 和 Translation 纹理的缩放和位移
            fixed4 _Diffuse;
            fixed4 _Specular;
            float _Gloss;

            v2f vert(a2v v){
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv = v.texcoord.xy * _MainTex_ST.xy + _MainTex_ST.zw;     // 将当前uv坐标应用纹理的缩放和位移设置
                o.worldNormal = UnityObjectToWorldNormal(v.normal);
                o.worldPos = mul(unity_ObjectToWorld,v.vertex).xyz;
                
                return o;
            }

            fixed4 frag(v2f i) : SV_TARGET{                
                // 对纹理进行采样,获得反射率
                fixed4 albedo = tex2D(_MainTex,i.uv) * _Diffuse;
                // 环境光
                fixed4 ambient = UNITY_LIGHTMODEL_AMBIENT * albedo;

                // 归一化法线   
                fixed3 worldNormal = normalize(i.worldNormal);
                // 获得光源方向
                fixed3 worldLightDir = normalize(UnityWorldSpaceLightDir(i.worldPos));
                // 计算漫反射光照
                fixed3 diffuse = albedo.rgb * max(0,dot(worldNormal,worldLightDir));
                // 获得观察方向
                fixed3 worldViewDir = normalize(UnityWorldSpaceViewDir(i.worldPos));
                // 计算Blinn模型的half变量,避免计算反射方向
                fixed3 halfDir = normalize(worldViewDir+worldLightDir);
                // 计算高光反射
                fixed3 specular = _Specular.rgb * pow(max(0,dot(worldNormal,halfDir)),_Gloss);

                // 着色
                return fixed4(ambient.rgb + diffuse + specular,1.0f);
            }

            ENDCG
        }
    }
    FallBack "Diffuse"
    
}