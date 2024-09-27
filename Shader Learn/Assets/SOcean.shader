
 
// nome do shader que aparece no material
Shader "Unlit/SOcean"
{
    Properties
    {
        // textura que aparece no material _nome nome da variavel 
        //("coisa", tipo) nome que aparece no editor, tipo da variavel = inicializacao
        _Color  ("Color", Color) = (0,0,1,1)
        _MainTex ("Normal", 2D) = "white" {}

        _AmplitudeX ("AmplitudeX", float) = 1
        _SpeedX ("SpeedX", float) = 1 
        _WaveLengthX ("WaveLengthX", float) =1
        
        _AmplitudeZ ("AmplitudeZ", float) = 1
        _SpeedZ ("SpeedZ", float) = 1 
        _WaveLengthZ ("WaveLengthZ", float) =1 

    }
    // bloco de codigo que define o comportamento do shader
    SubShader
    {
        // tags que definem o comportamento do shader
        Tags { "RenderType"="Transparent" }
        //define o lod deste subshader para posterior uso (muito raro)
        LOD 100
        //pass é uma etapa de renderizacao do shader (pode ter mais de uma)
        Pass
        {
            //inicio do codigo do shader em CGprogram (parecido com HLSL)
            CGPROGRAM
            //vertex se refere a funcao que processa os vertices
            #pragma vertex vert
            //fragment se refere a funcao que processa os fragmentos
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog
 
 
            #include "UnityCG.cginc"
 
            //struct que define os dados de entrada do vertex shader
            struct appdata
            {
                //variaveis de entrada de placa (semantica)
                //os tipod de semantica podem ser: POSITION, NORMAL, TEXCOORD0, TEXCOORD1, TEXCOORD2, TEXCOORD3, COLOR, TANGENT
                float4 vertex : POSITION;
                float4 normal : NORMAL;
                float2 uv : TEXCOORD0;
                float4 color: COLOR;
            };
            //struct que define os dados de saida do vertex shader e entrada do fragment shader
            //TEXCOORD0 é a semantica da variavel uv
            //Os tipos podem ser TEXCOORD0, TEXCOORD1, TEXCOORD2, TEXCOORD3, COLOR ,SV_POSITION, POSITION ou NORMAL
            struct v2f
            {
                float2 uv : TEXCOORD0;
                UNITY_FOG_COORDS(1)
                float4 vertex : SV_POSITION;
                float3 normal :NORMAL;
            };
            //variavel que define a textura do material
            //na unity o nome ser o mesmo do shaderlab referencia a variavel automaticamente
            sampler2D _MainTex;
            //variavel que define a transformacao da textura
            //na unity o _ST referencia automaticamente ao parametro de Tiling e Offset do material
            float4 _MainTex_ST;
            float4 _Color;

            
            float _AmplitudeX;
            float _SpeedX;
            float _WaveLengthX;

            float _AmplitudeZ;
            float _SpeedZ;
            float _WaveLengthZ;

            float waveFunctionZ;
            float waveFunction;
            float4 pos;
            float4 waveZ;
            float4 waveX;

            //funcao que processa os vertices
            v2f vert (appdata vEnter)
            {
                v2f output;
                pos = vEnter.vertex;
                waveFunction = _AmplitudeX  * sin( _SpeedX * _Time + _WaveLengthX* pos.x);
                waveFunctionZ = _AmplitudeZ  * sin( _SpeedZ * _Time + _WaveLengthZ* pos.z);

                waveZ += waveFunctionZ;
                waveX += waveFunction;
                pos.y += waveZ + waveX;
                
                output.vertex = UnityObjectToClipPos(pos);
               
                //passa a uv para o fragment shader
                //TRANSFORM_TEX é uma macro que transforma a uv de acordo com o tiling e offset
                output.uv = TRANSFORM_TEX(vEnter.uv, _MainTex);

                output.normal = vEnter.normal.xyz;

                //passa a coordenada do vertice para o fog
                UNITY_TRANSFER_FOG(output,output.vertex);

                return output;
            }

            fixed4 frag (v2f input) : SV_Target
            {
                //light from unity
                float3 lightDir = _WorldSpaceLightPos0.xyz;

                fixed4 norm = tex2D(_MainTex, input.uv + _Time.xx);
                fixed4 norm2 = tex2D(_MainTex, input.uv * 0.8 - _Time.xx);
                
                float bright = dot(input.normal * norm * norm2, lightDir);

                // apply fog
                UNITY_APPLY_FOG(input.fogCoord, col);


                return _Color * bright * 10;
            }
            ENDCG
        }
    }
}