Shader "Volume xx/PostEffect/Distortion Screen" {
    Properties {
        // 主纹理,用于屏幕后处理的话,
        // MainTex默认被设置为当前屏幕图像
        _MainTex("Main Tex",2D) = "white" {}
        // 扭曲强度
        _DistortFactor("DistortFactor",Float) = 0
    }
    SubShader {
        Pass {
            Tags { "LightMode" = "ForwardBase" }

            ZTest Always
            Cull Off
            Fog{ Mode off }
            CGPROGRAM

			#pragma fragmentoption ARB_precision_hint_fastest 
            #pragma vertex vert
            #pragma fragment frag
            
            #include "UnityCG.cginc"
            
            struct a2v{
                float4 vertex : POSITION;
                float4 texcoord : TEXCOORD0;
            };
            struct v2f{
                float4 pos : SV_POSITION;
                float2 uv : TEXCOORD0;
                float2 nosieUv : TEXCOORD1;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            float _DistortFactor;
            // 扭曲中心点,是一个uv坐标,(0.5,0.5)表示屏幕中心点(其实就是整个uv坐标的中心点)
            float4 _DistortCenter;  
            // 噪声图
            sampler2D _NoiseTex;
            float4 _NoiseTex_ST;
            // 扰动强度
            float _DistortStrength;

            v2f vert(a2v v){
                v2f o;
                // 变换顶点
                o.pos = UnityObjectToClipPos(v.vertex);

                // 获得uv坐标
                o.uv = TRANSFORM_TEX(v.texcoord,_MainTex);
                o.nosieUv = TRANSFORM_TEX(v.texcoord,_NoiseTex);

                return o;
            }

            fixed4 frag(v2f i) : SV_TARGET{
                // 从屏幕中心指向当前顶点的方向
                // 表示偏移的方向
                float2 dir = i.uv - _DistortCenter.xy;

                // 屏幕收缩偏移的值
                float2 scaleOffset = _DistortFactor*normalize(dir)*(1-length(dir));

                // 对噪声图进行采样
                fixed4 noise = tex2D(_NoiseTex,i.nosieUv);
                // 获得噪声偏移值,越靠近外边的部分,扰动越严重(dir值越大)
                float2 noiseOffset = noise.xy * _DistortStrength * dir;

                float2 offset = scaleOffset - noiseOffset;

                // 计算采样uv值= 正常uv + 从中间向边缘逐渐增加的采样距离
                float2 uv = i.uv + offset;
                return tex2D(_MainTex,uv);
            }


            ENDCG
        }
    }
    FallBack "Diffuse"
    
}