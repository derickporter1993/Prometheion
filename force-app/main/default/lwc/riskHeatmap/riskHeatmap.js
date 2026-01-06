import { LightningElement, api } from 'lwc';

export default class RiskHeatmap extends LightningElement {
    @api risks = [];

    get riskMatrix() {
        // Organize risks by severity and framework
        let matrix = {};
        
        if (this.risks && this.risks.length > 0) {
            for (let risk of this.risks) {
                let key = risk.framework + '_' + risk.severity;
                if (!matrix[key]) {
                    matrix[key] = 0;
                }
                matrix[key]++;
            }
        }
        
        return matrix;
    }

    get riskClass() {
        return (severity) => {
            if (severity === 'CRITICAL') return 'risk-critical';
            if (severity === 'HIGH') return 'risk-high';
            if (severity === 'MEDIUM') return 'risk-medium';
            return 'risk-low';
        };
    }
}
