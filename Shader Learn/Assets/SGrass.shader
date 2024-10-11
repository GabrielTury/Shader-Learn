Shader "GeometryGrassShader"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        //_NormalTex("Texture", 2D) = "white" {}
        //_NormalForce("NormalForce", Range(-2,2)) = 1
        //_SpecForce("SpecularForce", Range(0,2)) = 1
        _grassWidth("GrassWidth", Range(0,1)) = 0.2
        _grassHeight("GrassHeight", Range(0,5)) = 1
        _grassOffset("GrassOffset", Range(0,1)) = 0
        _grassShadow("GrassShadow", Range(0,1)) = 0.2
        _windSpeed("WindSpeed", Range(0,10)) = 1
    }
        SubShader
        {
            Tags { "RenderType" = "Opaque" }
            LOD 100
            Cull Off
            Pass
            {
                HLSLPROGRAM
                    #pragma vertex vert
                    #pragma fragment frag
                    #pragma target 3.0
                    #pragma geometry geom
                    #include  "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
                    #include  "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

               
                texture2D _MainTex;
                SamplerState sampler_MainTex;
                texture2D _NormalTex;
                SamplerState sampler_NormalTex;
                float _NormalForce;
                float _SpecForce;
                float _grassWidth;
                float _grassHeight;
                float _grassOffset;
                float _grassShadow;
                float _windSpeed;
               
                struct Attributes
                {
                    float4 position :POSITION;
                    half2 uv       :TEXCOORD0;
                    half3 normal : NORMAL;
                    half4 color : COLOR;
                };
            
                struct Varyings 
                {
                    float4 positionVAR :SV_POSITION;
                    float4 locpositionVAR :COLOR1;
                    half2 uvVAR       : TEXCOORD0;
                    half3 normalVar : NORMAL;
                    half4 colorVar : COLOR0;
                };

                Varyings vert(Attributes Input)
                {
                    Varyings Output;
                    float3 position = Input.position.xyz;
                    Output.positionVAR = TransformObjectToHClip(position);
                    Output.locpositionVAR = float4(position,1);
                    Output.uvVAR = Input.uv;
                    Output.colorVar = Input.color;
                    Output.normalVar = TransformObjectToWorldNormal(Input.normal);

                    return Output;
                }

                /*float rand(float x) 
                {
                    return frac(sin(x * 12.9898) * 43758.5453);
                }*/

                [maxvertexcount(30)]
                void geom(triangle Varyings Input[3], inout TriangleStream<Varyings> triStream)
                {
                    Varyings Output;

                    Varyings v;
                    float dist = 0.1;
                    for(int j=0; j<9; j++)
                    {
                        //float randomOffset = rand(j * _Time.x);

                        v = Input[0];

                        v.positionVAR = Input[0].positionVAR + float4(0.2*sin(_Time.x*_windSpeed*5+_grassOffset*j)+j*dist/*  * randomOffset */,-_grassHeight,0,0);
                        triStream.Append(v);

                        v.positionVAR = Input[0].positionVAR + float4(-_grassWidth+j*dist,0,0,0);
                        v.colorVar = Input[0].colorVar * float4(_grassShadow,_grassShadow * 1.2f,_grassShadow,0);
                        //v.colorVar = float4(0,1,0,0);
                        triStream.Append(v);

                        v.positionVAR = Input[0].positionVAR + float4(_grassWidth+j*dist,0,0,0);
                        v.colorVar = Input[0].colorVar * float4(_grassShadow,_grassShadow * 1.2f,_grassShadow,0);
                        //v.colorVar = float4(0,1,0,0);
                        triStream.Append(v);
                    }
                    
                    
                    for(int i = 0; i < 3; i++)
                    {
                        Output = Input[i];
                        triStream.Append(Output);
                    }
                }

                half4 frag(Varyings Input) :SV_TARGET
                { 
                    half4 color = Input.colorVar;
                    
                    Light l = GetMainLight();

                   half4 normalmap= _NormalTex.Sample(sampler_NormalTex, Input.uvVAR)*2-1;

                   float intensity = dot(l.direction, Input.normalVar+ normalmap.xzy* _NormalForce);

                   float3 viewDirection = normalize(_WorldSpaceCameraPos
                       - mul(unity_ObjectToWorld, Input.locpositionVAR).xyz);
                   
                   color *= _MainTex.Sample(sampler_MainTex, Input.uvVAR);
                   color *= intensity;


                    return color;
                }



            ENDHLSL
        }
    }
}
