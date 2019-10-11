shader_type canvas_item;

uniform sampler2D points;
uniform int numCellsPerAxis;
uniform int numSlices;
uniform int slice;

void fragment()
{
	float cellSize = 1.0f / float(numCellsPerAxis);
	int num_cells = numCellsPerAxis * numCellsPerAxis * numCellsPerAxis;
	vec3 samplePosition = vec3(UV, float(slice) / float(numSlices)) / cellSize;
	ivec3 curCell = ivec3(floor(samplePosition));
	
	float minSqrDist = 1.0;
	
	for (int x_offset = -1; x_offset <= 1; x_offset++)
	{
		for (int y_offset = -1; y_offset <= 1; y_offset++)
		{
			for (int z_offset = -1; z_offset <= 1; z_offset++)
			{
				ivec3 adjCell = curCell + ivec3(x_offset, y_offset, z_offset);
				
				// Wrap around if adjacent cell is out of bounds.
				if (adjCell.x == -1 || adjCell.x == numCellsPerAxis) adjCell.x = (adjCell.x + numCellsPerAxis) % numCellsPerAxis;
				if (adjCell.y == -1 || adjCell.y == numCellsPerAxis) adjCell.y = (adjCell.y + numCellsPerAxis) % numCellsPerAxis;
				if (adjCell.z == -1 || adjCell.z == numCellsPerAxis) adjCell.z = (adjCell.z + numCellsPerAxis) % numCellsPerAxis;
				
				int cellIndex = adjCell.x + numCellsPerAxis * (adjCell.y  + numCellsPerAxis * adjCell.z);
				vec3 pointPosition = texelFetch(points, ivec2(cellIndex, 0), 0).xyz;
				vec3 cellPosition = vec3(ivec3(curCell) + ivec3(x_offset, y_offset, z_offset));
				vec3 sampleOffset = samplePosition - (pointPosition + cellPosition);
				minSqrDist = min(minSqrDist, dot(sampleOffset, sampleOffset));
			}
		}
	}
	COLOR = vec4(sqrt(minSqrDist), 0.0, 0.0, 1.0);
}