/*
    基于深度纹理实现的扫描线效果,效果就是,一道扫描线从深度大的地方一路扫到深度小的地方(即以靠近摄像机的方向)

    基本思路是:
        设置深度最大阈值和最小阈值,只有当前像素在这个范围内,才会出现扫描线的特征(如高亮)
*/
Shader "Volume 08/Depth Normal Texture/ScanLine With Depth Texture" {
    Properties {
        _MainTex("Main Texture",2D) = "white" {}

        // 扫描线宽度
        _Width("Scan Line Width",Range(0.0,1.0)) = 0.05

        // 扫描线阈值,只有当前深度大于阈值小于阈值+宽度,才出现扫描线的特征
        // 初始值为远裁剪平面
        _Throsle("Scan Line Throsle",Range(0.0,1.0)) = 1

        // 扫描线强度
        _ScanLineStrength("Scan Line Strength",Float) = 1

        // 扫描线颜色
        _Color("Scan Line Color",Color) = (1, 1, 1, 1)
    }
    SubShader {
        Pass {
        
        CGPROGRAM
        
        #include "UnityCG.cginc"

        #pragma vertex vert
        #pragma fragment frag

        sampler2D _MainTex;
        sampler2D _CameraDepthTexture;
        fixed _Width;
        fixed _Throsle;
        fixed4 _Color;
        float _ScanLineStrength;

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
            // 获得范围在[0,1]之间的观察空间下的深度
            fixed depth = Linear01Depth(SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture,i.uv));

            // 屏幕本身的颜色
            fixed4 color = tex2D(_MainTex,i.uv);

            if(depth>=_Throsle && depth<=_Width+_Throsle)
                return color * _Color * _ScanLineStrength;
            else    
                return color;
                
        }

        ENDCG

        }
    }
    FallBack "Diffuse"
    
}