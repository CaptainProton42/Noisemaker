shader_type canvas_item;

uniform bool inverted;
uniform sampler2D pointsR;
uniform sampler2D pointsG;
uniform sampler2D pointsB;
uniform int numCellsR;
uniform int numCellsG;
uniform int numCellsB;
uniform bool enableChannelR;
uniform bool enableChannelG;
uniform bool enableChannelB;

void fragment()
{	
	COLOR = vec4(0.0f, 0.0f, 0.0f, 1.0f);

	for (int channel = 0; channel < 3; channel++)
	{
		if (channel == 0 && !enableChannelR) continue;
		if (channel == 1 && !enableChannelG) continue;
		if (channel == 2 && !enableChannelB) continue;
		
		int numCellsPerAxis;
		if (channel == 0) numCellsPerAxis = numCellsR;
		else if (channel == 1) numCellsPerAxis = numCellsG;
		else if (channel == 2) numCellsPerAxis = numCellsB;
		
		float cellSize = 1.0f / float(numCellsPerAxis);
		int num_cells = numCellsPerAxis * numCellsPerAxis;
		vec2 samplePosition = vec2(UV) / cellSize;
		ivec2 curCell = ivec2(floor(samplePosition));
		
		float minSqrDist = 1.0;
		
		for (int x_offset = -1; x_offset <= 1; x_offset++)
		{
			for (int y_offset = -1; y_offset <= 1; y_offset++)
			{
				ivec2 adjCell = curCell + ivec2(x_offset, y_offset);
				
				// Wrap around if adjacent cell is out of bounds.
				if (adjCell.x == -1 || adjCell.x == numCellsPerAxis) adjCell.x = (adjCell.x + numCellsPerAxis) % numCellsPerAxis;
				if (adjCell.y == -1 || adjCell.y == numCellsPerAxis) adjCell.y = (adjCell.y + numCellsPerAxis) % numCellsPerAxis;
				
				int cellIndex = adjCell.x + numCellsPerAxis * adjCell.y;
				vec3 pointPosition;

				if (channel == 0) pointPosition = texelFetch(pointsR, ivec2(adjCell.x, adjCell.y), 0).xyz;
				if (channel == 1) pointPosition = texelFetch(pointsG, ivec2(adjCell.x, adjCell.y), 0).xyz;
				if (channel == 2) pointPosition = texelFetch(pointsB, ivec2(adjCell.x, adjCell.y), 0).xyz;
				
				vec3 cellPosition = vec3(ivec3(curCell, 0) + ivec3(x_offset, y_offset, 0));
				vec3 sampleOffset = vec3(samplePosition, 0.0f) - (pointPosition + cellPosition);
				minSqrDist = min(minSqrDist, dot(sampleOffset, sampleOffset));
			}
		}
		if (channel == 0) COLOR.r = sqrt(minSqrDist);
		else if (channel == 1) COLOR.g = sqrt(minSqrDist);
		else if (channel == 2) COLOR.b = sqrt(minSqrDist);
	}
	if (inverted) {
		if (enableChannelR) COLOR.r = 1.0 - COLOR.r;
		if (enableChannelG) COLOR.g = 1.0 - COLOR.g;
		if (enableChannelB) COLOR.b = 1.0 - COLOR.b;
	}
}