import { LightningElement, wire, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from '@salesforce/apex';
import getEscalationPaths from '@salesforce/apex/EscalationPathController.getPaths';
import createPath from '@salesforce/apex/EscalationPathController.createPath';
import updatePath from '@salesforce/apex/EscalationPathController.updatePath';
import deletePath from '@salesforce/apex/EscalationPathController.deletePath';

const LEVEL_BADGES = {
    1: { label: 'L1', variant: 'success' },
    2: { label: 'L2', variant: 'warning' },
    3: { label: 'L3', variant: 'error' }
};

export default class EscalationPathConfig extends LightningElement {
    @track paths = [];
    @track isLoading = true;
    @track isModalOpen = false;
    @track isDeleteModalOpen = false;
    @track selectedPath = null;
    @track isEditMode = false;

    wiredPathsResult;

    @track formData = {
        userId: '',
        level: 1,
        role: 'Team Lead',
        notificationMethod: 'Both',
        delayMinutes: 15,
        active: true
    };

    get levelOptions() {
        return [
            { label: 'Level 1 - Team Lead', value: 1 },
            { label: 'Level 2 - Manager', value: 2 },
            { label: 'Level 3 - CISO/Director', value: 3 }
        ];
    }

    get roleOptions() {
        return [
            { label: 'Team Lead', value: 'Team Lead' },
            { label: 'Manager', value: 'Manager' },
            { label: 'CISO', value: 'CISO' },
            { label: 'Director', value: 'Director' },
            { label: 'VP', value: 'VP' }
        ];
    }

    get notificationMethodOptions() {
        return [
            { label: 'Mobile Push Only', value: 'Mobile' },
            { label: 'Email Only', value: 'Email' },
            { label: 'Mobile + Email', value: 'Both' },
            { label: 'All Channels', value: 'All' }
        ];
    }

    get delayOptions() {
        return [
            { label: '5 minutes', value: 5 },
            { label: '10 minutes', value: 10 },
            { label: '15 minutes', value: 15 },
            { label: '30 minutes', value: 30 },
            { label: '45 minutes', value: 45 },
            { label: '60 minutes', value: 60 }
        ];
    }

    get modalTitle() {
        return this.isEditMode ? 'Edit Escalation Path' : 'New Escalation Path';
    }

    get hasPaths() {
        return this.paths && this.paths.length > 0;
    }

    get level1Paths() {
        return this.paths.filter(p => p.level === 1);
    }

    get level2Paths() {
        return this.paths.filter(p => p.level === 2);
    }

    get level3Paths() {
        return this.paths.filter(p => p.level === 3);
    }

    @wire(getEscalationPaths)
    wiredPaths(result) {
        this.wiredPathsResult = result;
        this.isLoading = true;
        if (result.data) {
            this.paths = result.data.map(path => ({
                id: path.Id,
                userId: path.User__c,
                userName: path.User__r ? path.User__r.Name : '',
                userEmail: path.User__r ? path.User__r.Email : '',
                level: Number(path.Level__c),
                role: path.Role__c,
                notificationMethod: path.Notification_Method__c,
                delayMinutes: Number(path.Escalation_Delay_Minutes__c),
                active: path.Active__c,
                badge: LEVEL_BADGES[Number(path.Level__c)]
            }));
            this.isLoading = false;
        } else if (result.error) {
            this.handleError(result.error);
            this.isLoading = false;
        }
    }

    handleNewPath() {
        this.isEditMode = false;
        this.resetFormData();
        this.isModalOpen = true;
    }

    handleEdit(event) {
        const pathId = event.currentTarget.dataset.id;
        const path = this.paths.find(p => p.id === pathId);
        if (path) {
            this.isEditMode = true;
            this.selectedPath = path;
            this.formData = {
                id: path.id,
                userId: path.userId,
                level: path.level,
                role: path.role,
                notificationMethod: path.notificationMethod,
                delayMinutes: path.delayMinutes,
                active: path.active
            };
            this.isModalOpen = true;
        }
    }

    handleDeleteConfirm(event) {
        const pathId = event.currentTarget.dataset.id;
        this.selectedPath = this.paths.find(p => p.id === pathId);
        this.isDeleteModalOpen = true;
    }

    handleInputChange(event) {
        const field = event.target.dataset.field;
        let value;

        if (event.target.type === 'checkbox') {
            value = event.target.checked;
        } else if (field === 'level' || field === 'delayMinutes') {
            value = Number(event.target.value);
        } else {
            value = event.target.value;
        }

        this.formData = { ...this.formData, [field]: value };
    }

    async handleSave() {
        if (!this.validateForm()) {
            return;
        }

        this.isLoading = true;
        try {
            const pathData = {
                User__c: this.formData.userId,
                Level__c: this.formData.level,
                Role__c: this.formData.role,
                Notification_Method__c: this.formData.notificationMethod,
                Escalation_Delay_Minutes__c: this.formData.delayMinutes,
                Active__c: this.formData.active
            };

            if (this.isEditMode) {
                pathData.Id = this.formData.id;
                await updatePath({ path: pathData });
                this.showToast('Success', 'Escalation path updated successfully', 'success');
            } else {
                await createPath({ path: pathData });
                this.showToast('Success', 'Escalation path created successfully', 'success');
            }

            this.closeModal();
            await refreshApex(this.wiredPathsResult);
        } catch (error) {
            this.handleError(error);
        } finally {
            this.isLoading = false;
        }
    }

    async handleDelete() {
        this.isLoading = true;
        try {
            await deletePath({ pathId: this.selectedPath.id });
            this.showToast('Success', 'Escalation path deleted successfully', 'success');
            this.isDeleteModalOpen = false;
            await refreshApex(this.wiredPathsResult);
        } catch (error) {
            this.handleError(error);
        } finally {
            this.isLoading = false;
        }
    }

    closeModal() {
        this.isModalOpen = false;
        this.resetFormData();
    }

    closeDeleteModal() {
        this.isDeleteModalOpen = false;
        this.selectedPath = null;
    }

    validateForm() {
        const allValid = [...this.template.querySelectorAll('lightning-input, lightning-combobox')]
            .reduce((validSoFar, input) => {
                input.reportValidity();
                return validSoFar && input.checkValidity();
            }, true);

        if (!this.formData.userId) {
            this.showToast('Error', 'Please select a user', 'error');
            return false;
        }

        return allValid;
    }

    resetFormData() {
        this.formData = {
            userId: '',
            level: 1,
            role: 'Team Lead',
            notificationMethod: 'Both',
            delayMinutes: 15,
            active: true
        };
        this.selectedPath = null;
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }

    handleError(error) {
        const message = error.body?.message || error.message || 'An error occurred';
        this.showToast('Error', message, 'error');
    }

    handleRefresh() {
        this.isLoading = true;
        refreshApex(this.wiredPathsResult).finally(() => {
            this.isLoading = false;
        });
    }
}
