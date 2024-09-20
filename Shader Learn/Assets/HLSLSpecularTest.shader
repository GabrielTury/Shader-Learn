Shader "HLSLSpecular"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Specultar("Specular", Range(0,5)) = 1
 
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100
 
        Pass
        {
            HLSLPROGRAM 
                #pragma vertex vert
                #pragma fragment frag
                #include  "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
                #include  "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
 
                struct Attributes
                {
                    float4 position :POSITION;
                    float2 uv       :TEXCOORD0;
                    float4 normal   : NORMAL;
                };
                struct Varyings 
                {
                    float4 positionVAR :SV_POSITION;
                    float2 uvVAR       : TEXCOORD0;
                    float3 normal      : NORMAL;
                };
 
                texture2D _MainTex;
                float4 _MainTex_ST;
                SamplerState sampler_MainTex;

                float _Specular;
 
                Varyings vert(Attributes Input)
                {
                    Varyings Output;
 
                    Output.positionVAR = TransformObjectToHClip(Input.position.xyz);
                    Output.uvVAR = Input.uv * _MainTex_ST.xy + _MainTex_ST.zw;
                    Output.normal = TransformObjectToWorldNormal(Input.normal);
                    return Output;
                }
                float4 frag(Varyings Input) :SV_TARGET
                { 
                    float4 color = _MainTex.Sample(sampler_MainTex, Input.uvVAR);

                    float3 cameraViewDir = normalize(_WorldSpaceCameraPos - Input.positionVAR.xyz);

                    Light l = GetMainLight();

                    float specular = dot(normalize(cameraViewDir + l.direction), Input.normal);

                    float intensity = dot(l.direction, Input.normal);

                    color += half4(l.color,1) * saturate(specular) * _Specular;
 
                    return color * intensity;
                }
 
            ENDHLSL
        }
    }
}