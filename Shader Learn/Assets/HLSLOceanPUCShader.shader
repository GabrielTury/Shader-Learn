Shader "ReinaldoShader"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _NormalTex("Waves Normal", 2D) = "white" {}
        _NormalForce("NormalForce", Range(-2,2)) = 1
        _Specular ("Specular", Range(0, 2)) = 0.5
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
                    //This is the include for the core library
                    #include  "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
                    #include  "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
                    #include  "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderVariablesFunctions.hlsl"
 
                texture2D _MainTex;
                //SamplerState are used to define how the texture is sampled
                SamplerState sampler_MainTex;
                float4 _MainTex_ST;
                texture2D _NormalTex;
                float4    _NormalTex_ST;
                float _Specular;
                SamplerState sampler_NormalTex;
 
                float _NormalForce;
 
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
                    //Transform the vertex position from object space to clip space
                    Output.positionVAR = TransformObjectToHClip(position);
                    //Transform the UVs using the texture matrix to account for tiling and offset
                    Output.uvVAR = (Input.uv * _MainTex_ST.xy + _MainTex_ST.zw);
 
                    Output.colorVar = Input.color;
                    //Transform the normal from object space to world space
                    Output.normalVar = TransformObjectToWorldNormal(Input.normal);
 
                    return Output;
                }
                //The fragment function is where the final color of the pixel is calculated
                //SV_TARGET is the semantic for the final color of the pixel
                half4 frag(Varyings Input) :SV_TARGET
                { 
                    half4 color = Input.colorVar;
 
                    // Get the main light
                    Light l = GetMainLight();
                    // Get the direction of the camera
                    float3 viewDir = GetViewForwardDir();
 
                    // Sample the normal map
                    float2 normalUV = (Input.uvVAR * _NormalTex_ST.xy + _NormalTex_ST.zw);
                    half4 normalmap = _NormalTex.Sample(sampler_NormalTex, half2(_Time.x + normalUV.x, normalUV.y)) * 2 - 1;
                    half4 normalmap2 = _NormalTex.Sample(sampler_NormalTex, half2(normalUV.x, _Time.x + normalUV.y)) * 2 - 1;
 
                    normalmap = normalize(normalmap + normalmap2) * _NormalForce;
                    float3 normalMapSample = normalmap.rgb * 2.0 - 1.0; // Convert from [0,1] to [-1,1]
                    // Calculate the modified normal
                    float3 modifiedNormal = normalize(Input.normalVar + normalMapSample);
                    // Calculate the cross normal for reflections
                    float3 crossNormal = cross(float3(0, 0, -1), modifiedNormal);
                    // Reflect direction
                    float3 reflectDir = reflect(-l.direction, crossNormal);
                    // Calculate the specular
                    float3 halfwayDir = normalize(l.direction + viewDir);
                    float spec = pow(max(dot(crossNormal, halfwayDir), 0.0), 16.0) * _Specular;
 
                    // Calculate the intensity of the light
                    float intensity = max(dot(l.direction, crossNormal), 0);
                    // Combine the results
                    color *= _MainTex.Sample(sampler_MainTex, Input.uvVAR) * intensity + spec;
 
                    return color;
                }
 
 
            ENDHLSL
        }
    }
}