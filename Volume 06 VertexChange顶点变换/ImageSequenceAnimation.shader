Shader "Volume 06/Time/ImageSequenceAnimation" {
    Properties {
        // 序列帧图片
        _MainTex("Main Texture",2D) = "white" {}
        // 动画播放速度
        _Speed("Speed",Range(0.1,10)) = 1
        // 序列帧图片一共多少行
        _RowAmount("Row Amount",Float) = 0
        // 序列帧图片一共多少列
        _ColAmount("Col Amount",Float) = 0
    }
    SubShader {
        Tags { "RenderType"="Transparent" "Queue"="Transparent" "IgnoreProjector"="True" }
        Pass {
            ZWrite Off
            Blend SrcAlpha OneMinusSrcAlpha

            CGPROGRAM
            
            #include "UnityCG.cginc"

            #pragma vertex vert
            #pragma fragment frag

            sampler2D _MainTex;
            float _Speed;
            float _RowAmount;
            float _ColAmount;

            struct v2f{
                float4 pos : SV_POSITION;
                float2 uv : TEXCOORD0;
            };

            v2f vert(appdata_img v){
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv = v.texcoord;
                return o;
            }

            fixed4 frag(v2f i) : SV_TARGET{
                float time = floor(_Time.y * _Speed) % (_ColAmount*_RowAmount);
                // 获得行列
                float row = floor(time/_RowAmount);
                float col = floor(time%_ColAmount);

                float2 uv = float2(i.uv.x/_ColAmount,i.uv.y/_RowAmount);
                uv.x += row/_RowAmount;
                uv.y -= col/_ColAmount;

                fixed4 color = tex2D(_MainTex,uv);

                return color;
            }

            ENDCG
        }
    }
    FallBack "Diffuse"
    
}