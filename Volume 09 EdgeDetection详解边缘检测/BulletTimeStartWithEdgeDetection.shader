Shader "Volume xx/PostEffect/BulletTimeStartWithEdgeDetection" {
    Properties {
        _MainTex("MainTex",2D) = "white" {}
        // 只显示边缘线的程度,为1时,只显示边缘线,为0时,不显示
        _EdgeOnly("Edge Only",Float) = 1.0
        // 边缘颜色
        _EdgeColor("Edge Color",Color) = (0, 0, 0, 1)
        // 背景颜色
        _BackgroundColor("Background Color",Color) = (1, 1, 1, 1)
        // 进行卷积运算时,采样的范围
        _SampleDistance("Sample Distance",Float) = 1.0
        // _Sensitivity的xy分量分别对应了法线和深度的检测灵敏度,ZW分量没用
        _Sensitivity("Sensitivity",Vector) = (1, 1, 1, 1)
        // 扫描线最小阈值(即当前像素的世界坐标与中心点的距离只要大于这个阈值,就会表现出扫描线的特征)
        _Throsle("Throsle",Float) = 5
    }
    SubShader {
        Pass {
            CGPROGRAM
            
            #include "UnityCG.cginc"

            #pragma vertex vert
            #pragma fragment frag

            sampler2D _MainTex;
            float4 _MainTex_TexelSize;
            float _EdgeOnly;
            fixed4 _EdgeColor;
            fixed4 _BackgroundColor;
            float _SampleDistance;
            float4 _Sensitivity;
            sampler2D _CameraDepthNormalsTexture;       // Unity提供的深度/法线图
            float _Throsle;

            // 该扩散扫描线的中心点(世界坐标下)
            float4 _CenterPos;

            // 用于重建世界坐标
            // 一个4*4的矩阵,每一行包含从当前摄像机触发指向近裁剪平面四个顶点的一条射线
            float4x4 _FrustumCornersRay;

            // 噪声图
            sampler2D _NoiseTex;
            // Mask图
            sampler2D _MaskTex;

            // 摄像机距离远裁剪平面的距离值
            float _Far;

            struct v2f{
                float4 pos : SV_POSITION;

                // 从当前摄像机出发,指向当前顶点的一条射线(包含方向和距离信息,不可归一化)   
                float4 interpolatedRay : TEXCOORD0;

                // 用于在纹理周围进行法线和深度的采样
                float2 uv[5] : TEXCOORD1;       
            };

            v2f vert(appdata_img v){
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);

                half2 uv = v.texcoord;
                o.uv[0] = uv;

                o.uv[1] = uv + _MainTex_TexelSize.xy * half2(1,1) * _SampleDistance;
                o.uv[2] = uv + _MainTex_TexelSize.xy * half2(-1,-1) * _SampleDistance;
                o.uv[3] = uv + _MainTex_TexelSize.xy * half2(-1,1) * _SampleDistance;
                o.uv[4] = uv + _MainTex_TexelSize.xy * half2(1,-1) * _SampleDistance;

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

            fixed CheckSame(fixed4 center,fixed4 sample){
                fixed2 centerNormal = center.xy;
                float centerDepth = DecodeFloatRG(center.zw);
                fixed2 sampleNormal = sample.xy;
                float sampleDepth = DecodeFloatRG(sample.zw);

                fixed2 diffNormal = abs(centerNormal - sampleNormal) * _Sensitivity.x;
                int isSameNormal = (diffNormal.x + diffNormal.y) < 0.1;

                float diffDepth = abs(centerDepth - sampleDepth) * _Sensitivity.y;
                int isSameDepath = diffDepth < 0.1 * centerDepth;

                return isSameNormal*isSameDepath ? 1.0 : 0.0;
            }

            fixed4 frag(v2f i) : SV_TARGET{
                fixed4 sample1 = tex2D(_CameraDepthNormalsTexture,i.uv[1]);
                fixed4 sample2 = tex2D(_CameraDepthNormalsTexture,i.uv[2]);
                fixed4 sample3 = tex2D(_CameraDepthNormalsTexture,i.uv[3]);
                fixed4 sample4 = tex2D(_CameraDepthNormalsTexture,i.uv[4]);

                // edge为0时表示两点之间存在一条边界
                fixed edge = 1.0;
                
                edge *= CheckSame(sample1,sample2);
                edge *= CheckSame(sample3,sample4);

                // 获得在视角空间下的深度值
                float depth = DecodeFloatRG(tex2D(_MainTex,i.uv[0]).zw);        // 此时depth的深度在[0,1]之间,要乘于远裁剪平面将其变换到视角空间下
                depth *= _Far;

                // 根据深度值及射线,重建当前像素的世界坐标
                float3 worldPos = _WorldSpaceCameraPos + depth * i.interpolatedRay.xyz;                            

                // 得到当前像素(世界坐标)与中心点(世界坐标)的距离
                float distances = distance(worldPos,_CenterPos.xyz) + tex2D(_NoiseTex,i.uv[0]) * 5;

                // 当前像素颜色
                fixed4 color = tex2D(_MainTex,i.uv[0]);

                fixed4 withEdgeColor = lerp(_EdgeColor,color,edge);
                fixed4 onlyEdgeColor = lerp(_EdgeColor,_BackgroundColor,edge);

                // Mask图的r通道决定了当前像素是否取消边缘检测效果
                fixed isMaskOnlyEdgeColor = tex2D(_MaskTex,i.uv[0]).r;

                fixed4 finalColor = lerp(withEdgeColor,onlyEdgeColor,_EdgeOnly);

                finalColor = lerp(finalColor,withEdgeColor,isMaskOnlyEdgeColor);

                // 判断当前像素是否在扫描线上,如果在,那么表现扫描线的特征
                if(distances>_Throsle)
                    return withEdgeColor;

                return finalColor;
            }

            ENDCG
        }
    }
    FallBack "Diffuse"
    
}