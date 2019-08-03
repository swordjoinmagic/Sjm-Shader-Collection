/*
    法线可视化
*/
Shader "Volume 06/Vertex Change/Gemo Visual Normal" {
    Properties {
        _MainTex("Textrue",2D) = "white" {}
        _Mangitude("Mangitude",Float) = 1
    }
    SubShader {

        Tags { "Queue"="Geometry" "RenderType"="Opaque" }

        Pass{
            CGPROGRAM

            #pragma vertex vert
            #pragma fragment frag

            struct a2v{
                float4 vertex : POSITION;                
                float2 texcoord : TEXCOORD0;
            };

            struct v2f{
                float4 pos : SV_POSITION;
                float2 uv : TEXCOORD0;
            };

            sampler2D _MainTex;

            v2f vert(a2v v){
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv = v.texcoord;
                return o;
            }

            fixed4 frag(v2f i) : SV_TARGET{
                return tex2D(_MainTex,i.uv);
            }

            ENDCG
        }

        Pass {
            CGPROGRAM
            
            #include "UnityCG.cginc"

            #pragma vertex vert
            #pragma geometry geom
            #pragma fragment frag

            struct a2v{
                float4 vertex : POSITION;
                float4 texcoord : TEXCOORD0;
                float3 normal : NORMAL;
            };

            struct v2g{
                float4 vertex : SV_POSITION;
                float2 uv : TEXCOORD0;
                float3 normal : TEXCOORD1;
            };

            struct g2f{
                float2 uv : TEXCOORD0;
                float4 pos : SV_POSITION;
                fixed4 color : TEXCOORD1;
            };

            sampler2D _MainTex;
            float _Mangitude;
            
            v2g vert(a2v v){
                v2g o;
                o.vertex = v.vertex;
                o.uv = v.texcoord;
                o.normal = v.normal;
                return o;
            }

            [maxvertexcount(9)]
            void geom(triangle v2g input[3],inout LineStream<g2f> outStream){ 
                    g2f o;                     

                    for(int i=0;i<3;i++){

                        o.pos = (input[i].vertex);
                        o.pos = UnityObjectToClipPos(o.pos);
                        o.uv = input[i].uv; 
                        o.color = fixed4(1,1,1,1);
                        outStream.Append(o);     

                        o.pos = input[i].vertex;
                        o.pos.xyz += input[i].normal*_Mangitude;                        
                        o.pos = UnityObjectToClipPos(o.pos);
                        o.uv = input[i].uv;
                        o.color = fixed4(1,1,1,1);
                        outStream.Append(o);    

                        o.pos = (input[i].vertex);
                        o.pos = UnityObjectToClipPos(o.pos);
                        o.uv = input[i].uv; 
                        o.color = fixed4(1,1,1,1);
                        outStream.Append(o);                    
                    }
                    
                 
                //-------restart strip可以模拟一个primitives list 
                outStream.RestartStrip(); 
            } 


            fixed4 frag(g2f i) : SV_TARGET{
                return i.color;
            }
            ENDCG
        }
    }
    FallBack "Diffuse"
    
}