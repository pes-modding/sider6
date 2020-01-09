Texture2D tx2D : register( t0 );
SamplerState samLinear : register( s0 );

struct PS_INPUT
{
    float4 Pos : SV_POSITION;
    float4 Tex : TEXCOORD0;
};

float4 siderTexPS( PS_INPUT input) : SV_Target
{
    float4 clr = tx2D.Sample( samLinear, input.Tex.xy );
    clr.a = min(0.8f, clr.a);
    return clr;
    //return float4(input.Tex.x,input.Tex.y,0.0f,0.4f);
    //return float4(1.0f,0.0f,0.0f,0.4f);
};
