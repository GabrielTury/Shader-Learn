Shader "PUCLitShaderOcean"
{
    Properties
    {
        _Color  ("Color", Color) = (0,0,1,1)
        _NormalTex ("Normal", 2D) = "white" {}

        _AmplitudeX ("AmplitudeX", float) = 1
        _SpeedX ("SpeedX", float) = 1 
        _WaveLengthX ("WaveLengthX", float) =1
        
        _AmplitudeZ ("AmplitudeZ", float) = 1
        _SpeedZ ("SpeedZ", float) = 1 
        _WaveLengthZ ("WaveLengthZ", float) =1 

        _Specular("Specular", float) = 1
        _NormalForce("Normal Force", float) = 1
    }
        SubShader
        {
            Tags { "RenderType" = "Transparent" }
            LOD 100
            Pass
            {
                HLSLPROGRAM
                    #pragma vertex vert
                    #pragma fragment frag
                    #include  "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
                    #include  "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

               
                float4 _Color;
                texture2D _NormalTex;
                SamplerState sampler_NormalTex;
                float4 _NormalTex_ST;
                float _NormalForce;

                float _AmplitudeX;
                float _SpeedX;
                float _WaveLengthX;

                float _AmplitudeZ;
                float _SpeedZ;
                float _WaveLengthZ;

                float waveFunction;
                float waveFunctionZ;

                float _Specular;

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
                    half2 uvVAR       : TEXCOORD0;
                    half3 normalVar : NORMAL;
                    half4 colorVar : COLOR0;
                };

                Varyings vert(Attributes Input)
                {
                    Varyings Output;
                    float3 position = Input.position.xyz;
                    
                    Output.uvVAR = (Input.uv * _NormalTex_ST.xy + _NormalTex_ST.zw);//tiling
                    Output.colorVar = Input.color;
                    //Input.normal *= _NormalTex_ST;

                    Output.normalVar = TransformObjectToWorldNormal(Input.normal);

                    float4 waveZ = 0;
                    float4 waveX = 0;
                
                    waveFunction = _AmplitudeX  * sin( _SpeedX * _Time + _WaveLengthX* position.x);
                    waveFunctionZ = _AmplitudeZ  * sin( _SpeedZ * _Time + _WaveLengthZ* position.z);

                    waveZ += waveFunctionZ;
                    waveX += waveFunction;
                    position.y += waveZ + waveX;

                    
                    Output.positionVAR = TransformObjectToHClip(position);
               

                    return Output;
                }

                float4 frag(Varyings Input) :SV_TARGET
                { 
                    float4 color = _Color;
                    
                    float3 viewDir = GetViewForwardDir();;

                    Light l = GetMainLight();

                    // Sample normal map
                    float4 normalmap = _NormalTex.Sample(sampler_NormalTex, Input.uvVAR * _NormalTex_ST.xy + _Time.x) * 2 - 1;

                // Combine normals
                    float3 normal = normalize(Input.normalVar + normalmap.xyz * _NormalForce);

                    float intensity = dot(l.direction, normal);

                    float3 halfDir = normalize(viewDir - l.direction);
                    float specular = pow(max(dot(normal, halfDir), 0.0), _Specular);

                    //float2 uv = Input.uvVAR +_Time;

                    color *= intensity;

                    color += float4(l.color,1)  * specular * _Specular;
                    //color *= normalmap;

                    return color;
                }

            ENDHLSL
        }
    }
}