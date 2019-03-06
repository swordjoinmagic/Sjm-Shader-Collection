// 广告版+序列帧,用于将2D动画特效转变为 伪`3D特效
Shader "Volume 06/Time/Billboarding Image Sequence Animation" {
    Properties {
        _MainTex("Main Texture",2D) = "white" {}
        _Color("Color Tint",Color) = (1, 1, 1, 1)
        // 是固定法线还是固定向上的位置,为1时,公告板up向量固定,为0时,公告板表面法线(即视角方向)固定
        _VerticalBillboarding("Vertical Restraints",Range(0,1)) = 1
        // 动画播放速度
        _Speed("Speed",Range(0.1,10)) = 1
        // 序列帧图片一共多少行
        _RowAmount("Row Amount",Float) = 0
        // 序列帧图片一共多少列
        _ColAmount("Col Amount",Float) = 0
    }
    SubShader {
        Tags { "Queue"="Transparent" "IgnoreProjector"="True" "RenderType"="Transparent" "DisableBatching"="True" }
        Pass {
            
            Tags { "LightMode" = "ForwardBase" }

            ZWrite Off
            Blend SrcAlpha OneMinusSrcAlpha
            Cull Off    // 双面渲染

            CGPROGRAM
            
            #include "UnityCG.cginc"

            #pragma vertex vert
            #pragma fragment frag

            fixed4 _Color;
            sampler2D _MainTex;
            float _VerticalBillboarding;
            float _Speed;
            float _RowAmount;
            float _ColAmount;

            struct a2v{
                float4 vertex : POSITION;
                float2 texcoord : TEXCOORD0;
            };

            struct v2f{
                float4 pos : SV_POSITION;
                float2 uv : TEXCOORD;
            };

            v2f vert(a2v v){
                v2f o;

                // 规定锚点
                float3 center = float3(0,0,0);
                // 获得模型空间下的视角方向
                float3 viewer = mul(unity_WorldToObject,float4(_WorldSpaceCameraPos,1));
                

                // 获得表面法线
                float3 normalDir = viewer - center;
                // 根据_VerticalBillboarding判断法线是否固定方向
                normalDir.y = normalDir.y * _VerticalBillboarding;
                // 归一化法线
                normalDir = normalize(normalDir);

                // 根据法线和up的叉积获得向右的right向量
                float3 upDir = abs(normalDir.y) > 0.999 ? float3(0,0,1) : float3(0,1,0);
                float3 rightDir = normalize(cross(upDir,normalDir));
                // 根据rightDir和表面法线,获得修正过后的upDir
                upDir = normalize(cross(normalDir,rightDir));

                // 此时获得三个正交基(可以理解为顶点旋转之后的那个空间的三个坐标轴)
                float3 centerOffs = v.vertex.xyz - center;
                float3 localPos = center + rightDir*centerOffs.x + upDir*centerOffs.y+normalDir*centerOffs.z;

                // 顶点变换
                o.pos = UnityObjectToClipPos(float4(localPos,1));
                o.uv = v.texcoord;

                return o;
            }

            fixed4 frag(v2f i) : SV_TARGET{
                float time = floor(_Time.y * _Speed) % (_ColAmount*_RowAmount);
                // 获得行列
                float row = floor(time/_RowAmount);
                float col = floor(time%_ColAmount);

                float2 uv = float2(i.uv.x/_ColAmount,i.uv.y/_RowAmount);
                uv.x += col/_ColAmount;
                uv.y -= row/_RowAmount;

                fixed4 color = tex2D(_MainTex,uv) * _Color;

                return color;
            }

            ENDCG
            
        }
    }
    FallBack "Diffuse"
    
}