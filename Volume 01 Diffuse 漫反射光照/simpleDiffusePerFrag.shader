/*
    简单的逐片元漫反射光照
*/
Shader "Volume 01/Diffuse/Simple Diffuse Per Frag" {
    Properties {
        // 材质本身的漫反射颜色 
        _Diffuse("Diffuse Color",Color) = (1, 1, 1, 1)
    }
    SubShader {

        // 设置渲染类型为不透明物体,渲染队列也按不透明物体来
        Tags { "RenderType" = "Opaque" "Queue" = "Geometry" }

        Pass {
            // 设置渲染路径,此处使用前向渲染路径,用于让Unity底层渲染引擎填充内置光照变量
            Tags{ "LightMode" = "ForwardBase" }

            CGPROGRAM    

            // 定义顶点/片元着色器
            #pragma vertex vert
            #pragma fragment frag

            // 要使用_LightColor0(场景平行光光源颜色)变量,
            // 需要导入Lighting包
            #include "Lighting.cginc"

            // 材质漫反射颜色
            fixed4 _Diffuse;

            // 输入结构体,Application To Vertex
            struct a2v{
                float4 vertex : POSITION;
                float3 normal : NORMAL;
            };
            // 顶点着色器的输出结构体,Vertex To Fragment
            struct v2f{
                float4 pos : SV_POSITION;
                float3 worldNormal : TEXCOORD0;
                float3 worldPos : TEXCOORD1;
            };

            v2f vert(a2v v){
                v2f o;

                // 变换顶点到裁剪空间
                o.pos = UnityObjectToClipPos(v.vertex);

                // 获得世界坐标下的法线
                o.worldNormal = UnityObjectToWorldNormal(v.normal);

                // 获得世界坐标下的顶点坐标
                o.worldPos = UnityObjectToWorldDir(v.vertex).xyz;

                return o;
            }

            fixed4 frag(v2f i) : SV_TARGET{
                // 归一化法线
                fixed3 worldNormal = normalize(i.worldNormal);
                // 获得归一化光源方向(通过设置渲染路径获得)
                fixed3 worldDir = normalize(UnityWorldSpaceLightDir(i.worldPos));

                // 环境光
                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.rgb;

                // 计算漫反射光照
                fixed3 diffuse = _LightColor0.rgb * _Diffuse.rgb * max(0,dot(worldNormal,worldDir));

                return fixed4(ambient+diffuse,1);
            }

            ENDCG
        }
    }
    FallBack "Diffuse"
    
}