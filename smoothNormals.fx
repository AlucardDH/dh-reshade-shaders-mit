////////////////////////////////////////////////////////////////////////////////////////////////
//
// This code is extracted of DH_UBER_RT 0.20.6 (2025-03-04) and provided as is.
//
// This is free and under MIT license.
//
// This code is developed by AlucardDH (Damien Hembert)
//
// Get more here : https://alucarddh.github.io
// Join my Discord server for news, request, bug reports or help : https://discord.gg/V9HgyBRgMW
//
////////////////////////////////////////////////////////////////////////////////////////////////
  
  uniform bool bSmoothNormals <
      ui_label = "Smooth Normals";
  > = true;
  
  float2 getDepth(float2 coords) {
      return ReShade::GetLinearizedDepth(coords);
  }
 
 float3 getWorldPositionForNormal(float2 coords) {
      float depth = getDepth(coords).x;
      float3 result = float3((coords-0.5)*depth,depth);
      return result;
  }
 
 float4 mulByA(float4 v) {
      v.rgb *= v.a;
      return v;
  }


  float4 computeNormal(float3 wpCenter,float3 wpNorth,float3 wpEast) {
      return float4(normalize(cross(wpCenter - wpNorth, wpCenter - wpEast)),1.0);
  }
  
  float4 computeNormal(float2 coords,float3 offset,bool reverse) {
      float3 posCenter = getWorldPositionForNormal(coords);
      float3 posNorth  = getWorldPositionForNormal(coords - (reverse?-1:1)*offset.zy);
      float3 posEast   = getWorldPositionForNormal(coords + (reverse?-1:1)*offset.xz);
      
      float4 r = computeNormal(posCenter,posNorth,posEast);
      float mD = max(abs(posCenter.z-posNorth.z),abs(posCenter.z-posEast.z));
      if(mD>16) r.a = 0;
      return r;
  }

void PS_NormalPass(float4 vpos : SV_Position, float2 coords : TexCoord, out float4 outNormal : SV_Target0, out float4 outDepth : SV_Target1) {
      
      float3 offset = float3(ReShade::PixelSize, 0.0);
      
      float4 normal = computeNormal(coords,offset,false);
      if(normal.a==0) {
          normal = computeNormal(coords,offset,true);
      }
      
      if(bSmoothNormals) {
          float3 offset2 = offset * 7.5*(1.0-getDepth(coords).x);
          float4 normalTop = computeNormal(coords-offset2.zy,offset,false);
          float4 normalBottom = computeNormal(coords+offset2.zy,offset,false);
          float4 normalLeft = computeNormal(coords-offset2.xz,offset,false);
          float4 normalRight = computeNormal(coords+offset2.xz,offset,false);
          
          normalTop.a *= smoothstep(1,0,distance(normal.xyz,normalTop.xyz)*1.5)*2;
          normalBottom.a *= smoothstep(1,0,distance(normal.xyz,normalBottom.xyz)*1.5)*2;
          normalLeft.a *= smoothstep(1,0,distance(normal.xyz,normalLeft.xyz)*1.5)*2;
          normalRight.a *= smoothstep(1,0,distance(normal.xyz,normalRight.xyz)*1.5)*2;
          
          float4 normal2 = 
              mulByA(normal)
              +mulByA(normalTop)
              +mulByA(normalBottom)
              +mulByA(normalLeft)
              +mulByA(normalRight)
          ;
          if(normal2.a>0) {
              normal2.xyz /= normal2.a;
              normal.xyz = normalize(normal2.xyz);
          }
          
      }
      
      outNormal = float4(normal.xyz/2.0+0.5,1.0);
      outDepth = getDepth(coords);
      
  }
