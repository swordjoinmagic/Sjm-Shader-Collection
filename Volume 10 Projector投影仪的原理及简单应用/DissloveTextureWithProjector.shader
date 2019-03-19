/*
// 模仿Effect的Unity内置资源Projector Shader的写法
// 相比于自制的Projector,主要是多了个FallOff纹理
// 该纹理用于控制Projector不会出现双面渲染,同时
// 控制不在视椎体内的像素不着色
*/
Shader "Volume 10/Projector/Disslove Texture With Projector" {
    Properties {
        // 要投影的Texture
        _ProjTex("Projector Tex",2D) = "white" {}
        // 控制该Texture的颜色
        _Color("Color",Color) = (1, 1, 1, 1)
        // 衰减纹理
        _FalloffTex("Fall Off Texture",2D) = "white" {}
        // 噪声图,控制UV显示
        _NoiseTex("Noise Texture",2D) = "white" {}
        // 渐变阈值
        _EffectPercentage("EffectPercentage",Range(0,3)) = 0
    }
    SubShader {

        Tags { "Queue"="Transparent" }

        Pass {

            ZWrite Off
            ColorMask RGB
            Blend SrcAlpha OneMinusSrcAlpha
            Offset -1,-1

            CGPROGRAM
            
            #include "UnityCG.cginc"

            #pragma vertex vert
            #pragma fragment frag

            sampler2D _ProjTex;
            sampler2D _FalloffTex;
            fixed4 _Color;
            sampler2D _NoiseTex;
            float _EffectPercentage;

            struct v2f{
                float4 pos : SV_POSITION;
                // 物体经过Projector的VP矩阵转移到投影机的裁剪空间后
                // 根据物体顶点的裁剪空间坐标算出物体的屏幕坐标
                // 这个没有经过齐次除法的屏幕坐标就是uvProjector
                // 下一步要在片元着色器中进行齐次除法
                float4 uvProjector : TEXCOORD0;

                // 用于对FallOff纹理进行采样,用来保证不在视椎体内的顶点
                // 不会受投影仪影响
                float4 uvFallOff : TEXCOORD1;

                float2 uv : TEXCOORD2;
            };

            struct a2v{
                float4 vertex : POSITION;
                float2 texcoord : TEXCOORD0;
            };

            // 将顶点从世界坐标变换到投影机的裁剪空间内的VP矩阵
            float4x4 unity_Projector;

            // 用于变换顶点到一个不知名空间的矩阵(用于FallOFF纹理采样)..这个我不懂
            float4x4 unity_ProjectorClip;

            v2f vert(a2v v){
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);

                // 变换顶点到投影仪的裁剪空间
                o.uvProjector = mul(unity_Projector,v.vertex);
                o.uvFallOff = mul(unity_ProjectorClip,v.vertex);
                o.uv = v.texcoord;

                return o;
            }

            fixed4 frag(v2f i) : SV_TARGET{                
                // 相当于tex2D(_ProjTex,UNITY_PROJ_COORD(i.uvProjector).xy/UNITY_PROJ_COORD(i.uvProjector).w)
                fixed4 texS = tex2Dproj(_ProjTex,UNITY_PROJ_COORD(i.uvProjector));

                texS.rgb *= _Color.rgb;

                fixed4 texF = tex2Dproj(_FalloffTex,UNITY_PROJ_COORD(i.uvFallOff));

                texS.a = lerp(0,texS.a,texF.a);

                // 用噪声和阈值控制投影的图片的显示
                fixed degree = saturate(_EffectPercentage - (i.uv.y-i.uv.x) - tex2D(_NoiseTex,sin(i.uv.xx+cos(_Time.xy*0.2))));
                texS.a = lerp(texS.a,0,degree);
                texS.rgb = lerp(texS.rgb,fixed3(0,0,1),degree);
                
                return texS;
            }

            ENDCG
        }
    }
    FallBack "Diffuse"
    
}