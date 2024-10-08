//
//  ViewController.swift
//  MinionsOnFlatSurface
//
//  Created by 김종혁의 MacBook Pro on 2024/10/08.
//

import UIKit
import SceneKit
import ARKit

class ViewController: UIViewController, ARSCNViewDelegate {

    @IBOutlet var sceneView: ARSCNView!
    
    var dotNodes = [SCNNode]()
    var textNode = SCNNode()
    var planeNode = [SCNNode]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        sceneView.delegate = self
        
        sceneView.debugOptions = [ARSCNDebugOptions.showFeaturePoints]
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        let configuration = ARWorldTrackingConfiguration()
        
        configuration.planeDetection = [.horizontal]

        sceneView.session.run(configuration)
    }
    
    
    override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
        
        sceneView.session.pause()
    }
    
    @IBAction func undoPlane(_ sender: Any) {
        guard let tempPlane: SCNNode = planeNode.last else {return}

        planeNode.removeLast()
        
        tempPlane.removeFromParentNode()
    }

    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        if dotNodes.count >= 4 {
            for dot in dotNodes {
                dot.removeFromParentNode()
            }
            dotNodes = [SCNNode]()
            
        }
        
        if let touchLocation = touches.first?.location(in: sceneView){
            let hitTestResult = sceneView.hitTest(touchLocation, types: .featurePoint)
            
            if let hitResult = hitTestResult.first{
                addDot(at: hitResult)
            }
        }
        
        func addDot(at hitResult : ARHitTestResult){
            let dotGeometry = SCNSphere(radius: 0.0025)
            let material = SCNMaterial()
            material.diffuse.contents = UIColor.red
            
            dotGeometry.materials = [material]
            
            let dotNode = SCNNode(geometry: dotGeometry)
            
            dotNode.position = SCNVector3(x: hitResult.worldTransform.columns.3.x, y: hitResult.worldTransform.columns.3.y, z: hitResult.worldTransform.columns.3.z)
            
            sceneView.scene.rootNode.addChildNode(dotNode)
            
            dotNodes.append(dotNode)
            
            if dotNodes.count >= 4 {
                drawPlane(Points: dotNodes)
                
                for dot in dotNodes {
                    dot.removeFromParentNode()
                }
                dotNodes = [SCNNode]()
            }
        }
        
        func draw(Points: [SCNNode]) -> SCNGeometry {
            let verticesPosition = [
                Points[0].position,
                Points[1].position,
                Points[2].position,
                Points[3].position
            ]

            let textureCord = [
                CGPoint(x: 1, y: 1),
                CGPoint(x: 0, y: 1),
                CGPoint(x: 0, y: 0),
                CGPoint(x: 1, y: 0),
            ]

            let indices: [CInt] = [
                0, 2, 3,
                0, 1, 2
            ]

            let vertexSource = SCNGeometrySource(vertices: verticesPosition)
            let srcTex = SCNGeometrySource(textureCoordinates: textureCord)
            let date = NSData(bytes: indices, length: MemoryLayout<CInt>.size * indices.count)

            let scngeometry = SCNGeometryElement(data: date as Data,
    primitiveType: SCNGeometryPrimitiveType.triangles, primitiveCount: 2,
    bytesPerIndex: MemoryLayout<CInt>.size)

            let geometry = SCNGeometry(sources: [vertexSource,srcTex],
    elements: [scngeometry])

            return geometry
        }
        
        func drawPlane(Points: [SCNNode]){

            let polyDraw = draw(Points: Points)
            
            let (min, max) = polyDraw.boundingBox

            let width = CGFloat(max.x - min.x)
            let height = CGFloat(max.y - min.y)

            polyDraw.firstMaterial?.diffuse.contentsTransform = SCNMatrix4MakeScale(Float(width), Float(height), 1)

            let node = SCNNode()
            node.geometry = polyDraw
            planeNode.append(node)
            
            let texture: UIImage? = UIImage(named: "test.png")
            
            let material =  SCNMaterial()
            
            material.diffuse.contents = texture
            
            node.geometry?.materials = [material]
            
            sceneView.scene.rootNode.addChildNode(node)
        }
    }
}
