/*
    扩散扫描线,实现思路是:
    1. 根据深度纹理重建屏幕空间上每个像素的世界坐标
    2. 给定一个CenterPos(中心点),两个阈值,一个最大阈值,一个最小阈值
    3. 当某个像素的世界坐标与CenterPos的距离大于最小阈值,小于最大阈值使,表现出扫描线的特征

    问题的关键在于利用深度图重建世界坐标
*/
Shader "Volume 08/Depth Normal Texture/ScanLine With Rebuild WorldPos" {
    Properties {
        _MainTex("Main Texture",2D) = "white" {}
        
        // 扫描线最小阈值(即当前像素的世界坐标与中心点的距离只要大于这个阈值,就会表现出扫描线的特征)
        _Throsle("Throsle",Range(0.0,10)) = 5

        // 扫描线宽度(即当前像素的世界坐标与中心点的距离只要小于这个_Throsle+_Width且大于_Throsle,就会表现出扫描线的特征)
        _Width("Scan Line Width",Range(0.0,10)) = 0.1

        // 扫描线颜色
        _Color("Scan Line Color",Color) = (1, 1, 1, 1)

        // 扫描线强度
        _Strength("Scan Line Strength",Range(0,10)) = 1        
    }
    SubShader {
        Pass {

            CGPROGRAM
            
            #include "UnityCG.cginc"

            #pragma vertex vert
            #pragma fragment frag

            // 屏幕图像
            sampler2D _MainTex;
            float _Throsle;
            float _Width;
            float _Strength;
            fixed4 _Color;

            // 深度图
            sampler2D _CameraDepthTexture;

            // 该扩散扫描线的中心点(世界坐标下)
            float4 _CenterPos;

            // 一个4*4的矩阵,每一行包含从当前摄像机触发指向近裁剪平面四个顶点的一条射线
            float4x4 _FrustumCornersRay;

            struct v2f{
                float4 pos : SV_POSITION;
                float2 uv : TEXCOORD0;             

                // 从当前摄像机出发,指向当前顶点的一条射线(包含方向和距离信息,不可归一化)   
                float4 interpolatedRay : TEXCOORD1;
            };

            v2f vert(appdata_img v){
                v2f o;
                o.pos = UnityViewToClipPos(v.vertex);
                o.uv = v.texcoord;

                int index = 0;
                // 判断当前顶点偏向于近裁剪平面四个点中的哪个点
                if(v.texcoord.x<0.5 && v.texcoord.y < 0.5){
                    index = 0;
                }else if(v.texcoord.x>0.5 && v.texcoord.y>0.5){
                    index = 1;
                }else if(v.texcoord.x>0.5 && v.texcoord.y<0.5){
                    index = 2;
                }else{
                    index = 3;
                }

                o.interpolatedRay = _FrustumCornersRay[index];
                return o;
            }

            fixed4 frag(v2f i) : SV_TARGET{
                // 获得在视角空间下的深度值
                float depth = LinearEyeDepth(SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture,i.uv));
                // 根据深度值及射线,重建当前像素的世界坐标
                float3 worldPos = _WorldSpaceCameraPos + depth * i.interpolatedRay.xyz;

                // 得到当前像素(世界坐标)与中心点(世界坐标)的距离
                float distances = distance(worldPos,_CenterPos.xyz);

                // 当前像素颜色
                fixed4 color = tex2D(_MainTex,i.uv);

                // 判断当前像素是否在扫描线上,如果在,那么表现扫描线的特征
                if(distances>_Throsle && distances<_Throsle+_Width)
                    return color * _Color * _Strength;
                return color;
            }

            ENDCG

        }
    }
    FallBack "Diffuse"
    
}