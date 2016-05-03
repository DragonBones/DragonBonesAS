package dragonBones.starling.mesh 
{
	import dragonBones.objects.MeshData;
	import dragonBones.objects.VertexData;
	
	import starling.textures.Texture;

	/**
	 * ...
	 * @author sukui
	 */
	public class MeshQuadImage extends MeshImage
	{
		
		public function MeshQuadImage(texture:Texture) 
		{
			var w:Number = texture.width;
			var h:Number = texture.height;
			
			var meshData:MeshData = new MeshData();
			
			meshData.numVertex = 4;
			meshData.numTriangle = 2;
			meshData.vertices.fixed = false;
			meshData.vertices.length = 4;
			meshData.vertices.fixed = true;
			meshData.vertices[0] = new VertexData(0, 0, 0, 0);
			meshData.vertices[1] = new VertexData(0, h, 0, 1);
			meshData.vertices[2] = new VertexData(w, 0, 1, 0);
			meshData.vertices[3] = new VertexData(w, h, 1, 1);
			
			meshData.triangles.fixed = false;
			meshData.triangles.length = 6;
			meshData.triangles.fixed = true;
			meshData.triangles[0] = 0;
			meshData.triangles[1] = 1;
			meshData.triangles[2] = 2;
			meshData.triangles[3] = 1;
			meshData.triangles[4] = 3;
			meshData.triangles[5] = 2;
			super(texture, meshData);
		}
		
	}

}